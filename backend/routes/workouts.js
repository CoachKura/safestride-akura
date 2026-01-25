const express = require('express');
const { supabase } = require('../config/supabase');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(authenticate);

/**
 * GET /api/workouts/templates
 * Get all workout templates
 */
router.get('/templates', async (req, res) => {
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
 * GET /api/workouts/templates/:id
 * Get single workout template
 */
router.get('/templates/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: template, error } = await supabase
      .from('workout_templates')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!template) {
      return res.status(404).json({ error: 'Template not found' });
    }
    
    res.json(template);
  } catch (error) {
    console.error('Get template error:', error);
    res.status(500).json({ error: 'Failed to fetch workout template' });
  }
});

/**
 * PUT /api/workouts/scheduled/:id/status
 * Update scheduled workout status
 */
router.put('/scheduled/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    if (!['scheduled', 'completed', 'skipped', 'missed'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status value' });
    }
    
    const { data: workout, error } = await supabase
      .from('scheduled_workouts')
      .update({ status })
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    res.json(workout);
  } catch (error) {
    console.error('Update workout status error:', error);
    res.status(500).json({ error: 'Failed to update workout status' });
  }
});

/**
 * DELETE /api/workouts/scheduled/:id
 * Delete scheduled workout
 */
router.delete('/scheduled/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { error } = await supabase
      .from('scheduled_workouts')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
    
    res.json({ success: true });
  } catch (error) {
    console.error('Delete workout error:', error);
    res.status(500).json({ error: 'Failed to delete workout' });
  }
});

/**
 * POST /api/workouts/auto-match
 * Auto-match completed activities to scheduled workouts
 */
router.post('/auto-match', async (req, res) => {
  try {
    const { athleteId } = req.body;
    
    // Get unmatched activities
    const { data: activities, error: activitiesError } = await supabase
      .from('completed_activities')
      .select('*')
      .eq('athlete_id', athleteId)
      .is('scheduled_workout_id', null)
      .order('activity_date', { ascending: false })
      .limit(30);
    
    if (activitiesError) throw activitiesError;
    
    let matchedCount = 0;
    
    for (const activity of activities) {
      // Find scheduled workout on same date
      const activityDate = new Date(activity.activity_date).toISOString().split('T')[0];
      
      const { data: workout } = await supabase
        .from('scheduled_workouts')
        .select('id')
        .eq('athlete_id', athleteId)
        .eq('scheduled_date', activityDate)
        .eq('status', 'scheduled')
        .single();
      
      if (workout) {
        // Match activity to workout
        await supabase
          .from('completed_activities')
          .update({
            scheduled_workout_id: workout.id,
            auto_matched: true
          })
          .eq('id', activity.id);
        
        // Update workout status
        await supabase
          .from('scheduled_workouts')
          .update({ status: 'completed' })
          .eq('id', workout.id);
        
        matchedCount++;
      }
    }
    
    res.json({
      success: true,
      matched: matchedCount,
      total: activities.length
    });
  } catch (error) {
    console.error('Auto-match error:', error);
    res.status(500).json({ error: 'Failed to auto-match activities' });
  }
});

module.exports = router;
