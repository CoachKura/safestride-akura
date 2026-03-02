import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRAVA_CLIENT_ID = "162971"
const STRAVA_CLIENT_SECRET = "ca2a2ef68680c324e0ba4db3ed6e6006a9dc7626"

serve(async (req) => {
  try {
    const { athleteId, refreshToken } = await req.json()
    
    console.log('🔄 Refreshing Strava token for athlete:', athleteId)
    
    // Exchange refresh token for new access token
    const tokenResponse = await fetch('https://www.strava.com/oauth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: STRAVA_CLIENT_ID,
        client_secret: STRAVA_CLIENT_SECRET,
        grant_type: 'refresh_token',
        refresh_token: refreshToken
      })
    })
    
    if (!tokenResponse.ok) {
      throw new Error('Strava token refresh failed')
    }
    
    const tokenData = await tokenResponse.json()
    console.log('✅ New tokens received from Strava')
    
    // Update database
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    const { data, error } = await supabase
      .from('strava_connections')
      .update({
        access_token: tokenData.access_token,
        refresh_token: tokenData.refresh_token,
        expires_at: new Date(tokenData.expires_at * 1000).toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('athlete_id', athleteId)
      .select()
      .single()
    
    if (error) {
      throw new Error('Database update failed: ' + error.message)
    }
    
    console.log('✅ Database updated with new tokens')
    
    return new Response(JSON.stringify({ 
      success: true,
      data: data
    }), {
      headers: { 'Content-Type': 'application/json' }
    })
    
  } catch (error) {
    console.error('❌ Token refresh error:', error)
    return new Response(JSON.stringify({ 
      success: false,
      error: error.message 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
