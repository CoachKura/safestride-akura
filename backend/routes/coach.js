const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { supabase } = require('../config/supabase');
const { authenticateCoach } = require('../middleware/auth');
const { sendInvitationEmail } = require('../utils/email');

const router = express.Router();

// All routes require coach authentication
router.use(authenticateCoach);

/**
 * GET /api/coach/athletes
 * Get all athletes for the coach
 */
router.get('/athletes', async (req, res) => {
  try {
    const { data: athletes, error } = await supabase
      .from('v_athletes_with_zones')
      .select('*')
      .order('name');
    
    if (error) throw error;
    
    res.json(athletes);
  } catch (error) {
    console.error('Get athletes error:', error);
    res.status(500).json({ error: 'Failed to fetch athletes' });
  }
});

/**
 * GET /api/coach/athletes/:id
 * Get single athlete details
 */
router.get('/athletes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: athlete, error } = await supabase
      .from('v_athletes_with_zones')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!athlete) {
      return res.status(404).json({ error: 'Athlete not found' });
    }
    
    res.json(athlete);
  } catch (error) {
    console.error('Get athlete error:', error);
    res.status(500).json({ error: 'Failed to fetch athlete' });
  }
});

/**
 * POST /api/coach/invite
 * Send email invitation to athlete
 */
router.post('/invite', async (req, res) => {
  try {
    const { email, name } = req.body;
    
    if (!email || !name) {
      return res.status(400).json({ error: 'Email and name are required' });
    }
    
    // Check if athlete already exists
    const { data: existing } = await supabase
      .from('athletes')
      .select('id')
      .eq('email', email)
      .single();
    
    if (existing) {
      return res.status(400).json({ error: 'Athlete with this email already exists' });
    }
    
    // Generate unique invite token
    const inviteToken = uuidv4();
    
    // Create athlete record with invited status
    const { data: athlete, error: createError } = await supabase
      .from('athletes')
      .insert({
        coach_id: req.coachId,
        email,
        name,
        status: 'invited',
        invite_token: inviteToken,
        invite_sent_at: new Date().toISOString()
      })
      .select()
      .single();
    
    if (createError) throw createError;
    
    // Send invitation email
    const inviteUrl = `${process.env.FRONTEND_URL}/signup?token=${inviteToken}`;
    await sendInvitationEmail(email, name, inviteUrl);
    
    res.json({
      success: true,
      athlete: {
        id: athlete.id,
        email: athlete.email,
        name: athlete.name,
        status: athlete.status
      },
      inviteUrl
    });
  } catch (error) {
    console.error('Invite athlete error:', error);
    res.status(500).json({ error: 'Failed to send invitation' });
  }
});

/**
 * GET /api/coach/workouts/templates
 * Get all workout templates (7 protocols)
 */
router.get('/workouts/templates', async (req, res) => {
  try {
    const { data: templates, error } = await supabase
      .from('workout_templates')
      .select('*')
      .order('day_of_week');
    
    if (error) throw error;
    
    res.json(templates);
  } catch (error) {
    console.error('Get templates error:', error);
    res.status(500).json({ error: 'Failed to fetch workout templates' });
  }
});

/**
 * POST /api/coach/workouts/publish
 * Publish workouts to athlete calendars
 */
router.post('/workouts/publish', async (req, res) => {
  try {
    const {
      athleteIds,  // Array of athlete IDs (or 'all')
      startDate,   // YYYY-MM-DD
      endDate,     // YYYY-MM-DD
      weekPattern  // Array of template IDs for Mon-Sun
    } = req.body;
    
    if (!startDate || !endDate || !weekPattern || weekPattern.length !== 7) {
      return res.status(400).json({ error: 'Invalid request data' });
    }
    
    // Get athletes
    let athletes;
    if (athleteIds === 'all') {
      const { data, error } = await supabase
        .from('athletes')
        .select('id')
        .eq('coach_id', req.coachId)
        .eq('status', 'active');
      
      if (error) throw error;
      athletes = data.map(a => a.id);
    } else {
      athletes = athleteIds;
    }
    
    // Generate workout schedule
    const workouts = [];
    const start = new Date(startDate);
    const end = new Date(endDate);
    
    for (let date = new Date(start); date <= end; date.setDate(date.getDate() + 1)) {
      const dayOfWeek = date.getDay(); // 0 = Sunday
      const mondayBasedDay = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // Convert to Monday=0
      const templateId = weekPattern[mondayBasedDay];
      
      if (templateId) {
        for (const athleteId of athletes) {
          workouts.push({
            athlete_id: athleteId,
            template_id: templateId,
            scheduled_date: date.toISOString().split('T')[0],
            status: 'scheduled'
          });
        }
      }
    }
    
    // Batch insert workouts
    const { data: created, error: insertError } = await supabase
      .from('scheduled_workouts')
      .insert(workouts)
      .select();
    
    if (insertError) throw insertError;
    
    res.json({
      success: true,
      published: created.length,
      workouts: created
    });
  } catch (error) {
    console.error('Publish workouts error:', error);
    res.status(500).json({ error: 'Failed to publish workouts' });
  }
});

/**
 * GET /api/coach/calendar
 * Get training calendar for all athletes
 */
router.get('/calendar', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    let query = supabase
      .from('v_upcoming_workouts')
      .select('*')
      .order('scheduled_date');
    
    if (startDate) {
      query = query.gte('scheduled_date', startDate);
    }
    if (endDate) {
      query = query.lte('scheduled_date', endDate);
    }
    
    const { data: workouts, error } = await query;
    
    if (error) throw error;
    
    res.json(workouts);
  } catch (error) {
    console.error('Get calendar error:', error);
    res.status(500).json({ error: 'Failed to fetch calendar' });
  }
});

/**
 * GET /api/coach/dashboard/stats
 * Get dashboard statistics
 */
router.get('/dashboard/stats', async (req, res) => {
  try {
    // Get athlete counts
    const { data: athletes } = await supabase
      .from('athletes')
      .select('status')
      .eq('coach_id', req.coachId);
    
    const totalAthletes = athletes.length;
    const activeAthletes = athletes.filter(a => a.status === 'active').length;
    const invitedAthletes = athletes.filter(a => a.status === 'invited').length;
    
    // Get completion rate (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const { data: scheduled } = await supabase
      .from('scheduled_workouts')
      .select('status')
      .gte('scheduled_date', sevenDaysAgo.toISOString().split('T')[0])
      .lte('scheduled_date', new Date().toISOString().split('T')[0]);
    
    const totalScheduled = scheduled.length;
    const completed = scheduled.filter(w => w.status === 'completed').length;
    const completionRate = totalScheduled > 0 ? Math.round((completed / totalScheduled) * 100) : 0;
    
    res.json({
      totalAthletes,
      activeAthletes,
      invitedAthletes,
      completionRate,
      last7Days: {
        scheduled: totalScheduled,
        completed
      }
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard statistics' });
  }
});

/**
 * GET /api/coach/activities
 * Get recent completed activities
 */
router.get('/activities', async (req, res) => {
  try {
    const { limit = 20 } = req.query;
    
    const { data: activities, error } = await supabase
      .from('v_completed_activities_matched')
      .select('*')
      .order('activity_date', { ascending: false })
      .limit(limit);
    
    if (error) throw error;
    
    res.json(activities);
  } catch (error) {
    console.error('Get activities error:', error);
    res.status(500).json({ error: 'Failed to fetch activities' });
  }
});

module.exports = router;
