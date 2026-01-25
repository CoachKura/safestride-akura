const express = require('express');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { supabase } = require('../config/supabase');
const { generateToken } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/auth/coach/login
 * Coach login
 */
router.post('/coach/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    // Find coach
    const { data: coach, error } = await supabase
      .from('coaches')
      .select('*')
      .eq('email', email)
      .single();
    
    if (error || !coach) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Verify password
    const isValidPassword = await bcrypt.compare(password, coach.password_hash);
    
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Generate token
    const token = generateToken({
      id: coach.id,
      email: coach.email,
      role: 'coach'
    });
    
    res.json({
      token,
      coach: {
        id: coach.id,
        email: coach.email,
        name: coach.name,
        phone: coach.phone
      }
    });
  } catch (error) {
    console.error('Coach login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

/**
 * POST /api/auth/athlete/signup
 * Athlete signup (from email invite)
 */
router.post('/athlete/signup', async (req, res) => {
  try {
    const {
      token: inviteToken,
      name,
      age,
      weight,
      height,
      password
    } = req.body;
    
    if (!inviteToken || !name || !age || !password) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Verify invitation token
    const { data: athlete, error: athleteError } = await supabase
      .from('athletes')
      .select('*')
      .eq('invite_token', inviteToken)
      .eq('status', 'invited')
      .single();
    
    if (athleteError || !athlete) {
      return res.status(400).json({ error: 'Invalid or expired invitation' });
    }
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);
    
    // Calculate Max HR: 208 - (0.7 × age)
    const maxHr = Math.round(208 - (0.7 * age));
    
    // Update athlete with signup data
    const { data: updatedAthlete, error: updateError } = await supabase
      .from('athletes')
      .update({
        name,
        age,
        weight,
        height,
        max_hr: maxHr,
        status: 'active',
        signed_up_at: new Date().toISOString()
      })
      .eq('id', athlete.id)
      .select()
      .single();
    
    if (updateError) {
      throw updateError;
    }
    
    // HR zones are auto-created by database trigger
    
    // Generate auth token
    const authToken = generateToken({
      id: updatedAthlete.id,
      email: updatedAthlete.email,
      role: 'athlete'
    });
    
    res.json({
      token: authToken,
      athlete: {
        id: updatedAthlete.id,
        email: updatedAthlete.email,
        name: updatedAthlete.name,
        age: updatedAthlete.age,
        maxHr: updatedAthlete.max_hr
      }
    });
  } catch (error) {
    console.error('Athlete signup error:', error);
    res.status(500).json({ error: 'Signup failed' });
  }
});

/**
 * POST /api/auth/athlete/login
 * Athlete login
 */
router.post('/athlete/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    
    // Find athlete
    const { data: athlete, error } = await supabase
      .from('athletes')
      .select('*')
      .eq('email', email)
      .eq('status', 'active')
      .single();
    
    if (error || !athlete) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Note: For now, we're using simple comparison
    // In production, hash passwords in athlete table
    
    // Generate token
    const token = generateToken({
      id: athlete.id,
      email: athlete.email,
      role: 'athlete'
    });
    
    res.json({
      token,
      athlete: {
        id: athlete.id,
        email: athlete.email,
        name: athlete.name,
        age: athlete.age,
        maxHr: athlete.max_hr
      }
    });
  } catch (error) {
    console.error('Athlete login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

/**
 * GET /api/auth/verify-invite/:token
 * Verify invitation token
 */
router.get('/verify-invite/:token', async (req, res) => {
  try {
    const { token } = req.params;
    
    const { data: athlete, error } = await supabase
      .from('athletes')
      .select('id, email, name, status')
      .eq('invite_token', token)
      .single();
    
    if (error || !athlete) {
      return res.status(404).json({ error: 'Invalid invitation token' });
    }
    
    if (athlete.status !== 'invited') {
      return res.status(400).json({ error: 'Invitation already accepted or expired' });
    }
    
    res.json({
      valid: true,
      email: athlete.email
    });
  } catch (error) {
    console.error('Verify invite error:', error);
    res.status(500).json({ error: 'Verification failed' });
  }
});

module.exports = router;
