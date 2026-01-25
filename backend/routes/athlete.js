const express = require('express');
const { supabase } = require('../config/supabase');
const { authenticateAthlete } = require('../middleware/auth');

const router = express.Router();

// All routes require athlete authentication
router.use(authenticateAthlete);

/**
 * GET /api/athlete/profile
 * Get athlete profile with HR zones
 */
router.get('/profile', async (req, res) => {
  try {
    const { data: athlete, error } = await supabase
      .from('v_athletes_with_zones')
      .select('*')
      .eq('id', req.athleteId)
      .single();
    
    if (error) throw error;
    
    if (!athlete) {
      return res.status(404).json({ error: 'Profile not found' });
    }
    
    res.json(athlete);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

/**
 * PUT /api/athlete/profile
 * Update athlete profile
 */
router.put('/profile', async (req, res) => {
  try {
    const { name, age, weight, height } = req.body;
    
    const updates = {};
    if (name) updates.name = name;
    if (age) {
      updates.age = age;
      // Max HR will be recalculated by trigger
    }
    if (weight) updates.weight = weight;
    if (height) updates.height = height;
    
    const { data: athlete, error } = await supabase
      .from('athletes')
      .update(updates)
      .eq('id', req.athleteId)
      .select()
      .single();
    
    if (error) throw error;
    
    res.json(athlete);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

/**
 * GET /api/athlete/workouts/today
 * Get today's scheduled workout
 */
router.get('/workouts/today', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    
    const { data: workout, error } = await supabase
      .from('scheduled_workouts')
      .select(`
        *,
        template:workout_templates(*)
      `)
      .eq('athlete_id', req.athleteId)
      .eq('scheduled_date', today)
      .single();
    
    if (error) {
      // No workout for today
      return res.json({ workout: null });
    }
    
    // Get athlete's HR zones
    const { data: zones } = await supabase
      .from('hr_zones')
      .select('*')
      .eq('athlete_id', req.athleteId)
      .single();
    
    res.json({
      workout,
      hrZones: zones
    });
  } catch (error) {
    console.error('Get today workout error:', error);
    res.status(500).json({ error: 'Failed to fetch today\'s workout' });
  }
});

/**
 * GET /api/athlete/workouts/upcoming
 * Get upcoming scheduled workouts
 */
router.get('/workouts/upcoming', async (req, res) => {
  try {
    const { days = 7 } = req.query;
    const today = new Date();
    const endDate = new Date();
    endDate.setDate(today.getDate() + parseInt(days));
    
    const { data: workouts, error } = await supabase
      .from('scheduled_workouts')
      .select(`
        *,
        template:workout_templates(*)
      `)
      .eq('athlete_id', req.athleteId)
      .gte('scheduled_date', today.toISOString().split('T')[0])
      .lte('scheduled_date', endDate.toISOString().split('T')[0])
      .order('scheduled_date');
    
    if (error) throw error;
    
    res.json(workouts);
  } catch (error) {
    console.error('Get upcoming workouts error:', error);
    res.status(500).json({ error: 'Failed to fetch upcoming workouts' });
  }
});

/**
 * GET /api/athlete/workouts/calendar
 * Get workout calendar for date range
 */
router.get('/workouts/calendar', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    if (!startDate || !endDate) {
      return res.status(400).json({ error: 'startDate and endDate are required' });
    }
    
    const { data: workouts, error } = await supabase
      .from('scheduled_workouts')
      .select(`
        *,
        template:workout_templates(*)
      `)
      .eq('athlete_id', req.athleteId)
      .gte('scheduled_date', startDate)
      .lte('scheduled_date', endDate)
      .order('scheduled_date');
    
    if (error) throw error;
    
    res.json(workouts);
  } catch (error) {
    console.error('Get calendar error:', error);
    res.status(500).json({ error: 'Failed to fetch calendar' });
  }
});

/**
 * POST /api/athlete/activities/manual
 * Manually log a completed activity
 */
router.post('/activities/manual', async (req, res) => {
  try {
    const {
      scheduledWorkoutId,
      activityDate,
      distanceKm,
      durationMinutes,
      avgPace,
      avgHr
    } = req.body;
    
    if (!activityDate || !durationMinutes) {
      return res.status(400).json({ error: 'Activity date and duration are required' });
    }
    
    const activity = {
      athlete_id: req.athleteId,
      scheduled_workout_id: scheduledWorkoutId || null,
      activity_date: activityDate,
      distance_km: distanceKm,
      duration_minutes: durationMinutes,
      avg_pace: avgPace,
      avg_hr: avgHr,
      source: 'manual'
    };
    
    const { data: created, error } = await supabase
      .from('completed_activities')
      .insert(activity)
      .select()
      .single();
    
    if (error) throw error;
    
    // Update scheduled workout status if linked
    if (scheduledWorkoutId) {
      await supabase
        .from('scheduled_workouts')
        .update({ status: 'completed' })
        .eq('id', scheduledWorkoutId);
    }
    
    res.json(created);
  } catch (error) {
    console.error('Manual activity log error:', error);
    res.status(500).json({ error: 'Failed to log activity' });
  }
});

/**
 * GET /api/athlete/activities
 * Get activity history
 */
router.get('/activities', async (req, res) => {
  try {
    const { limit = 30 } = req.query;
    
    const { data: activities, error } = await supabase
      .from('completed_activities')
      .select(`
        *,
        scheduled_workout:scheduled_workouts(
          *,
          template:workout_templates(*)
        )
      `)
      .eq('athlete_id', req.athleteId)
      .order('activity_date', { ascending: false })
      .limit(limit);
    
    if (error) throw error;
    
    res.json(activities);
  } catch (error) {
    console.error('Get activities error:', error);
    res.status(500).json({ error: 'Failed to fetch activities' });
  }
});

/**
 * GET /api/athlete/stats
 * Get athlete statistics
 */
router.get('/stats', async (req, res) => {
  try {
    const { period = 'week' } = req.query; // week, month, year
    
    let daysAgo;
    switch (period) {
      case 'week': daysAgo = 7; break;
      case 'month': daysAgo = 30; break;
      case 'year': daysAgo = 365; break;
      default: daysAgo = 7;
    }
    
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - daysAgo);
    
    // Get completed activities
    const { data: activities } = await supabase
      .from('completed_activities')
      .select('distance_km, duration_minutes, avg_hr')
      .eq('athlete_id', req.athleteId)
      .gte('activity_date', startDate.toISOString());
    
    // Get scheduled workouts
    const { data: workouts } = await supabase
      .from('scheduled_workouts')
      .select('status')
      .eq('athlete_id', req.athleteId)
      .gte('scheduled_date', startDate.toISOString().split('T')[0])
      .lte('scheduled_date', new Date().toISOString().split('T')[0]);
    
    const totalDistance = activities.reduce((sum, a) => sum + (parseFloat(a.distance_km) || 0), 0);
    const totalTime = activities.reduce((sum, a) => sum + (a.duration_minutes || 0), 0);
    const avgHr = activities.length > 0 
      ? Math.round(activities.reduce((sum, a) => sum + (a.avg_hr || 0), 0) / activities.length)
      : 0;
    
    const scheduled = workouts.length;
    const completed = workouts.filter(w => w.status === 'completed').length;
    const completionRate = scheduled > 0 ? Math.round((completed / scheduled) * 100) : 0;
    
    res.json({
      period,
      totalActivities: activities.length,
      totalDistance: Math.round(totalDistance * 10) / 10,
      totalTimeMinutes: totalTime,
      avgHr,
      scheduled,
      completed,
      completionRate
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

/**
 * GET /api/athlete/devices
 * Get connected devices
 */
router.get('/devices', async (req, res) => {
  try {
    const { data: devices, error } = await supabase
      .from('device_connections')
      .select('provider, connected_at, last_sync_at, sync_enabled')
      .eq('athlete_id', req.athleteId)
      .order('connected_at', { ascending: false });
    
    if (error) throw error;
    
    res.json(devices);
  } catch (error) {
    console.error('Get devices error:', error);
    res.status(500).json({ error: 'Failed to fetch devices' });
  }
});

module.exports = router;
