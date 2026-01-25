const express = require('express');
const axios = require('axios');
const { supabase } = require('../config/supabase');
const { authenticateAthlete } = require('../middleware/auth');

const router = express.Router();

const STRAVA_CLIENT_ID = process.env.STRAVA_CLIENT_ID;
const STRAVA_CLIENT_SECRET = process.env.STRAVA_CLIENT_SECRET;
const STRAVA_REDIRECT_URI = process.env.STRAVA_REDIRECT_URI;

/**
 * GET /api/strava/auth-url
 * Generate Strava OAuth URL
 */
router.get('/auth-url', authenticateAthlete, (req, res) => {
  const scope = 'read,activity:read_all,activity:write';
  const state = req.athleteId; // Pass athlete ID as state
  
  const authUrl = `https://www.strava.com/oauth/authorize?` +
    `client_id=${STRAVA_CLIENT_ID}` +
    `&redirect_uri=${encodeURIComponent(STRAVA_REDIRECT_URI)}` +
    `&response_type=code` +
    `&approval_prompt=auto` +
    `&scope=${scope}` +
    `&state=${state}`;
  
  res.json({ authUrl });
});

/**
 * POST /api/strava/callback
 * Handle Strava OAuth callback
 */
router.post('/callback', authenticateAthlete, async (req, res) => {
  try {
    const { code, state } = req.body;
    
    if (!code) {
      return res.status(400).json({ error: 'Authorization code is required' });
    }
    
    // Exchange code for access token
    const tokenResponse = await axios.post('https://www.strava.com/oauth/token', {
      client_id: STRAVA_CLIENT_ID,
      client_secret: STRAVA_CLIENT_SECRET,
      code,
      grant_type: 'authorization_code'
    });
    
    const {
      access_token,
      refresh_token,
      expires_at,
      athlete: stravaAthlete
    } = tokenResponse.data;
    
    // Store or update device connection
    const { data: connection, error } = await supabase
      .from('device_connections')
      .upsert({
        athlete_id: req.athleteId,
        provider: 'strava',
        access_token,
        refresh_token,
        token_expires_at: new Date(expires_at * 1000).toISOString(),
        external_user_id: stravaAthlete.id.toString(),
        connected_at: new Date().toISOString(),
        sync_enabled: true
      }, {
        onConflict: 'athlete_id,provider'
      })
      .select()
      .single();
    
    if (error) throw error;
    
    res.json({
      success: true,
      connection,
      stravaAthlete: {
        id: stravaAthlete.id,
        username: stravaAthlete.username,
        firstname: stravaAthlete.firstname,
        lastname: stravaAthlete.lastname
      }
    });
  } catch (error) {
    console.error('Strava callback error:', error);
    res.status(500).json({ error: 'Failed to connect Strava' });
  }
});

/**
 * POST /api/strava/disconnect
 * Disconnect Strava
 */
router.post('/disconnect', authenticateAthlete, async (req, res) => {
  try {
    const { error } = await supabase
      .from('device_connections')
      .delete()
      .eq('athlete_id', req.athleteId)
      .eq('provider', 'strava');
    
    if (error) throw error;
    
    res.json({ success: true });
  } catch (error) {
    console.error('Strava disconnect error:', error);
    res.status(500).json({ error: 'Failed to disconnect Strava' });
  }
});

/**
 * GET /api/strava/activities
 * Fetch recent activities from Strava
 */
router.get('/activities', authenticateAthlete, async (req, res) => {
  try {
    // Get Strava connection
    const { data: connection, error } = await supabase
      .from('device_connections')
      .select('*')
      .eq('athlete_id', req.athleteId)
      .eq('provider', 'strava')
      .single();
    
    if (error || !connection) {
      return res.status(404).json({ error: 'Strava not connected' });
    }
    
    // Check if token needs refresh
    const expiresAt = new Date(connection.token_expires_at);
    let accessToken = connection.access_token;
    
    if (expiresAt < new Date()) {
      // Refresh token
      const refreshResponse = await axios.post('https://www.strava.com/oauth/token', {
        client_id: STRAVA_CLIENT_ID,
        client_secret: STRAVA_CLIENT_SECRET,
        grant_type: 'refresh_token',
        refresh_token: connection.refresh_token
      });
      
      accessToken = refreshResponse.data.access_token;
      
      // Update stored tokens
      await supabase
        .from('device_connections')
        .update({
          access_token: refreshResponse.data.access_token,
          refresh_token: refreshResponse.data.refresh_token,
          token_expires_at: new Date(refreshResponse.data.expires_at * 1000).toISOString()
        })
        .eq('id', connection.id);
    }
    
    // Fetch activities from Strava
    const activitiesResponse = await axios.get(
      'https://www.strava.com/api/v3/athlete/activities',
      {
        headers: {
          Authorization: `Bearer ${accessToken}`
        },
        params: {
          per_page: 30
        }
      }
    );
    
    res.json(activitiesResponse.data);
  } catch (error) {
    console.error('Fetch Strava activities error:', error);
    res.status(500).json({ error: 'Failed to fetch activities from Strava' });
  }
});

/**
 * POST /api/strava/sync
 * Sync recent Strava activities to database
 */
router.post('/sync', authenticateAthlete, async (req, res) => {
  try {
    // Get Strava connection
    const { data: connection } = await supabase
      .from('device_connections')
      .select('*')
      .eq('athlete_id', req.athleteId)
      .eq('provider', 'strava')
      .single();
    
    if (!connection) {
      return res.status(404).json({ error: 'Strava not connected' });
    }
    
    // Fetch activities (using same logic as above)
    let accessToken = connection.access_token;
    const expiresAt = new Date(connection.token_expires_at);
    
    if (expiresAt < new Date()) {
      const refreshResponse = await axios.post('https://www.strava.com/oauth/token', {
        client_id: STRAVA_CLIENT_ID,
        client_secret: STRAVA_CLIENT_SECRET,
        grant_type: 'refresh_token',
        refresh_token: connection.refresh_token
      });
      accessToken = refreshResponse.data.access_token;
    }
    
    const activitiesResponse = await axios.get(
      'https://www.strava.com/api/v3/athlete/activities',
      {
        headers: { Authorization: `Bearer ${accessToken}` },
        params: { per_page: 20 }
      }
    );
    
    const stravaActivities = activitiesResponse.data;
    
    // Insert activities into database
    const activities = stravaActivities
      .filter(a => a.type === 'Run')
      .map(activity => ({
        athlete_id: req.athleteId,
        activity_date: activity.start_date,
        distance_km: activity.distance / 1000,
        duration_minutes: Math.round(activity.moving_time / 60),
        duration_seconds: activity.moving_time,
        avg_pace: calculatePace(activity.distance, activity.moving_time),
        avg_hr: activity.average_heartrate ? Math.round(activity.average_heartrate) : null,
        max_hr: activity.max_heartrate ? Math.round(activity.max_heartrate) : null,
        elevation_gain: activity.total_elevation_gain,
        source: 'strava',
        external_id: activity.id.toString(),
        external_url: `https://www.strava.com/activities/${activity.id}`,
        raw_data: activity
      }));
    
    // Upsert activities (avoid duplicates)
    const { data: synced, error } = await supabase
      .from('completed_activities')
      .upsert(activities, {
        onConflict: 'athlete_id,external_id,source',
        ignoreDuplicates: true
      })
      .select();
    
    if (error) throw error;
    
    // Update last sync time
    await supabase
      .from('device_connections')
      .update({ last_sync_at: new Date().toISOString() })
      .eq('id', connection.id);
    
    res.json({
      success: true,
      synced: synced.length,
      activities: synced
    });
  } catch (error) {
    console.error('Sync Strava activities error:', error);
    res.status(500).json({ error: 'Failed to sync activities from Strava' });
  }
});

/**
 * POST /api/strava/webhook
 * Webhook endpoint for Strava activity updates
 */
router.post('/webhook', async (req, res) => {
  try {
    const { object_type, aspect_type, object_id, owner_id } = req.body;
    
    // Handle new activity creation
    if (object_type === 'activity' && aspect_type === 'create') {
      // Find athlete by Strava user ID
      const { data: connection } = await supabase
        .from('device_connections')
        .select('athlete_id, access_token')
        .eq('provider', 'strava')
        .eq('external_user_id', owner_id.toString())
        .single();
      
      if (connection) {
        // Fetch activity details from Strava
        const activityResponse = await axios.get(
          `https://www.strava.com/api/v3/activities/${object_id}`,
          {
            headers: { Authorization: `Bearer ${connection.access_token}` }
          }
        );
        
        const activity = activityResponse.data;
        
        if (activity.type === 'Run') {
          // Insert activity
          await supabase
            .from('completed_activities')
            .insert({
              athlete_id: connection.athlete_id,
              activity_date: activity.start_date,
              distance_km: activity.distance / 1000,
              duration_minutes: Math.round(activity.moving_time / 60),
              avg_pace: calculatePace(activity.distance, activity.moving_time),
              avg_hr: activity.average_heartrate ? Math.round(activity.average_heartrate) : null,
              source: 'strava',
              external_id: activity.id.toString(),
              raw_data: activity
            });
        }
      }
    }
    
    res.json({ success: true });
  } catch (error) {
    console.error('Strava webhook error:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

/**
 * GET /api/strava/webhook
 * Webhook verification (Strava requirement)
 */
router.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];
  
  if (mode === 'subscribe' && token === process.env.STRAVA_WEBHOOK_SECRET) {
    res.json({ 'hub.challenge': challenge });
  } else {
    res.status(403).json({ error: 'Forbidden' });
  }
});

// Helper function to calculate pace (min/km)
function calculatePace(distanceMeters, durationSeconds) {
  if (!distanceMeters || !durationSeconds) return null;
  const paceSeconds = (durationSeconds / (distanceMeters / 1000));
  const minutes = Math.floor(paceSeconds / 60);
  const seconds = Math.round(paceSeconds % 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}/km`;
}

module.exports = router;
