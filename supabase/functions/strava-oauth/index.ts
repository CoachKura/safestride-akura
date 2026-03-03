// Modern Deno.serve() pattern for Supabase Edge Functions
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
    const { code, athleteId } = await req.json()
    
    if (!code) {
      throw new Error('Authorization code is required')
    }

    console.log('🔄 Exchanging Strava authorization code for tokens...')

    const tokenResponse = await fetch('https://www.strava.com/oauth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: Deno.env.get('STRAVA_CLIENT_ID'),
        client_secret: Deno.env.get('STRAVA_CLIENT_SECRET'),
        code: code,
        grant_type: 'authorization_code',
      }),
    })

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      throw new Error('Strava API error: ' + error)
    }

    const tokenData = await tokenResponse.json()
    console.log('✅ Strava tokens received for athlete:', tokenData.athlete.id)

    const expiresAt = new Date(tokenData.expires_at * 1000).toISOString()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    const { data: connection, error: dbError } = await supabase
      .from('strava_connections')
      .upsert({
        athlete_id: athleteId || 'strava_' + tokenData.athlete.id,
        strava_athlete_id: tokenData.athlete.id,
        access_token: tokenData.access_token,
        refresh_token: tokenData.refresh_token,
        expires_at: expiresAt,
        athlete_data: tokenData.athlete,
        updated_at: new Date().toISOString(),
      }, {
        onConflict: 'athlete_id'
      })
      .select()
      .single()

    if (dbError) {
      console.error('❌ Database error:', dbError)
      throw new Error('Database error: ' + dbError.message)
    }

    console.log('✅ Strava connection saved to database')

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
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Strava OAuth error:', error.message)
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