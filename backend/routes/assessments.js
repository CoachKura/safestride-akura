// AKURA SafeStride Backend - Assessment Routes
// POST /api/assessments - Submit new assessment
// Last Updated: 2026-01-27

const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// POST /api/assessments - Submit new assessment
router.post('/', async (req, res) => {
  try {
    const assessmentData = req.body;
    
    // Basic validation
    if (!assessmentData.personal || !assessmentData.personal.age) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid assessment data',
          details: { field: 'personal', expected: 'Required fields missing' },
          requestId: req.id
        }
      });
    }
    
    // Calculate AIFRI score
    const aifriScore = calculateAIFRI(assessmentData);
    const scores = calculatePillarScores(assessmentData);
    const riskLevel = calculateRiskLevel(aifriScore);
    
    // Generate protocol ID (temporary until protocol generation implemented)
    const protocolId = `proto_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // Save to Supabase
    const { data, error } = await supabase
      .from('assessments')
      .insert({
        athlete_id: assessmentData.personal.email || 'unknown',
        assessment_data: assessmentData,
        aifri_score: aifriScore,
        scores: scores,
        risk_level: riskLevel,
        protocol_id: protocolId,
        created_at: new Date().toISOString()
      })
      .select()
      .single();
    
    if (error) {
      console.error('Supabase error:', error);
      throw new Error(`Database error: ${error.message}`);
    }
    
    // Return success response
    res.status(201).json({
      assessmentId: data?.id || `assess_${Date.now()}`,
      scores: {
        running: scores.running,
        strength: scores.strength,
        rom: scores.rom,
        balance: scores.balance,
        mobility: scores.mobility,
        alignment: scores.alignment
      },
      aifriTotal: aifriScore,
      riskLevel: riskLevel,
      protocolId: protocolId,
      createdAt: data?.created_at || new Date().toISOString()
    });
  } catch (error) {
    console.error(`Assessment error [${req.id}]:`, error);
    res.status(500).json({
      error: {
        code: 'ASSESSMENT_FAILED',
        message: error.message || 'Failed to process assessment',
        requestId: req.id
      }
    });
  }
});

// GET /api/assessments/:id - Get assessment by ID
router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('assessments')
      .select('*')
      .eq('id', req.params.id)
      .single();
    
    if (error) throw error;
    if (!data) {
      return res.status(404).json({
        error: {
          code: 'NOT_FOUND',
          message: 'Assessment not found',
          requestId: req.id
        }
      });
    }
    
    res.json(data);
  } catch (error) {
    console.error(`Get assessment error [${req.id}]:`, error);
    res.status(500).json({
      error: {
        code: 'FETCH_FAILED',
        message: error.message,
        requestId: req.id
      }
    });
  }
});

// Calculate AIFRI score (6-pillar system)
function calculateAIFRI(assessment) {
  const scores = calculatePillarScores(assessment);
  
  // Weighted average: Running 40%, Strength 15%, ROM 12%, Balance 13%, Mobility 10%, Alignment 10%
  const total = 
    (scores.running * 0.40) +
    (scores.strength * 0.15) +
    (scores.rom * 0.12) +
    (scores.balance * 0.13) +
    (scores.mobility * 0.10) +
    (scores.alignment * 0.10);
  
  return Math.round(Math.max(0, Math.min(100, total)));
}

// Calculate individual pillar scores
function calculatePillarScores(assessment) {
  return {
    running: calculateRunningScore(assessment),
    strength: calculateStrengthScore(assessment),
    rom: calculateROMScore(assessment),
    balance: calculateBalanceScore(assessment),
    mobility: calculateMobilityScore(assessment),
    alignment: calculateAlignmentScore(assessment)
  };
}

// Pillar 1: Running (40% weight)
function calculateRunningScore(assessment) {
  const running = assessment.running || {};
  const weeklyMileage = running.weeklyMileage || 0;
  const experience = assessment.goals?.experience || 'beginner';
  
  let score = Math.min(100, (weeklyMileage / 50) * 100);
  
  // Experience bonus
  if (experience === 'advanced') score += 10;
  else if (experience === 'intermediate') score += 5;
  
  return Math.round(Math.max(0, Math.min(100, score)));
}

// Pillar 2: Strength (15% weight)
function calculateStrengthScore(assessment) {
  const strength = assessment.strength || {};
  const plankHold = strength.plankHold || 0;
  const singleLegBalance = strength.singleLegBalance || 0;
  
  const score = (plankHold / 120) * 50 + (singleLegBalance / 60) * 50;
  return Math.round(Math.max(0, Math.min(100, score)));
}

// Pillar 3: ROM (12% weight)
function calculateROMScore(assessment) {
  const fms = assessment.fms || {};
  const totalScore = fms.totalScore || 14;
  
  const score = (totalScore / 21) * 100;
  return Math.round(Math.max(0, Math.min(100, score)));
}

// Pillar 4: Balance (13% weight)
function calculateBalanceScore(assessment) {
  const balance = assessment.balance || {};
  const singleLegEyesOpen = balance.singleLegEyesOpen || 0;
  const singleLegEyesClosed = balance.singleLegEyesClosed || 0;
  
  const score = (singleLegEyesOpen / 60) * 60 + (singleLegEyesClosed / 30) * 40;
  return Math.round(Math.max(0, Math.min(100, score)));
}

// Pillar 5: Mobility (10% weight)
function calculateMobilityScore(assessment) {
  const mobility = assessment.mobility || {};
  const rom = assessment.rom || {};
  
  const ankleScore = (rom.ankle || 0) / 45 * 100;
  const hipScore = ((mobility.sitReach || 0) + 20) / 70 * 100;
  
  const score = (ankleScore + hipScore) / 2;
  return Math.round(Math.max(0, Math.min(100, score)));
}

// Pillar 6: Alignment (10% weight) - NASM/ACSM standards
function calculateAlignmentScore(assessment) {
  const alignment = assessment.alignment || {};
  let score = 100;
  
  // Q-angle assessment (ideal 13-18°)
  const qAngle = alignment.qAngle || 16;
  if (qAngle < 8 || qAngle > 20) score -= 15;
  else if (qAngle < 10 || qAngle > 18) score -= 8;
  
  // Foot pronation
  if (alignment.footPronation === 'overpronation') score -= 12;
  else if (alignment.footPronation === 'moderate') score -= 6;
  
  // Pelvic tilt
  if (alignment.pelvicTilt === 'anterior') score -= 10;
  else if (alignment.pelvicTilt === 'posterior') score -= 8;
  
  // Forward head posture
  if (alignment.forwardHead === 'severe') score -= 15;
  else if (alignment.forwardHead === 'moderate') score -= 8;
  else if (alignment.forwardHead === 'mild') score -= 4;
  
  return Math.round(Math.max(0, Math.min(100, score)));
}

// Calculate risk level
function calculateRiskLevel(aifriScore) {
  if (aifriScore >= 80) return 'Low';
  if (aifriScore >= 60) return 'Moderate';
  return 'High';
}

module.exports = router;
