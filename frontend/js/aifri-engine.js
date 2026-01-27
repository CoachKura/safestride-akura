/* =============================================================================
   AKURA AIFRI-ENGINE.JS - 6-Pillar AIFRI Calculation Engine
   ============================================================================= */

class AIFRICalculator {
  constructor(assessmentData) {
    this.data = assessmentData;
    this.pillars = {};
    this.grades = {
      100: { label: 'ELITE', color: '#4caf50', range: '80-100' },
      79: { label: 'ADVANCED', color: '#4caf50', range: '70-79' },
      69: { label: 'INTERMEDIATE', color: '#ffc107', range: '60-69' },
      59: { label: 'DEVELOPING', color: '#ff8c42', range: '50-59' },
      0: { label: 'BEGINNER', color: '#e74c3c', range: '0-49' }
    };
  }

  /**
   * Main AIFRI Calculation - 6 Pillars
   * Formula: (Running×0.40) + (Strength×0.15) + (ROM×0.12) + (Balance×0.13) + (Mobility×0.10) + (Alignment×0.10)
   */
  calculateAIFRI() {
    this.pillars = {
      running: this.calculateRunningScore(),
      strength: this.calculateStrengthScore(),
      rom: this.calculateROMScore(),
      balance: this.calculateBalanceScore(),
      mobility: this.calculateMobilityScore(),
      alignment: this.calculateAlignmentScore()
    };

    const total = Math.round(
      (this.pillars.running * 0.40) +
      (this.pillars.strength * 0.15) +
      (this.pillars.rom * 0.12) +
      (this.pillars.balance * 0.13) +
      (this.pillars.mobility * 0.10) +
      (this.pillars.alignment * 0.10)
    );

    return {
      total: Math.min(100, total),
      pillars: this.pillars,
      grade: this.getGrade(total),
      breakdown: this.getBreakdown(total)
    };
  }

  /**
   * PILLAR 1: RUNNING (40% Weight)
   * - Race pace → VO2max equivalence
   * - Weekly mileage → aerobic base
   * - Injury history → current readiness
   * - Pain level → performance impact
   */
  calculateRunningScore() {
    let score = 0;

    // 5K Pace Assessment (converts to VO2max proxy)
    if (this.data.raceTime5K) {
      const minutes = this.parseTimeToMinutes(this.data.raceTime5K);
      const pace = 5 / minutes; // km/min
      const vo2Proxy = pace * 100; // Normalized scale

      score += Math.min(40, vo2Proxy); // 0-40 points
    } else {
      score += 20; // Default baseline
    }

    // Weekly Mileage (aerobic foundation)
    const weeklyKm = this.data.weeklyKm || 0;
    score += Math.min(25, (weeklyKm / 50) * 25); // 0-25 points

    // Running Years (experience)
    const runningYears = this.data.runningYears || 0;
    score += Math.min(15, Math.min(runningYears, 10) * 1.5); // 0-15 points

    // Injury Penalty (-2 per injury)
    const injuries = this.data.injuryHistory ? this.data.injuryHistory.split(',').length : 0;
    score -= injuries * 2;

    // Pain Level Penalty (0-10 scale)
    const painLevel = this.data.painLevel || 0;
    score -= (painLevel / 10) * 10; // 0-10 point deduction

    // Cap at 0-100
    return Math.max(0, Math.min(100, score));
  }

  /**
   * PILLAR 2: STRENGTH (15% Weight)
   * Split into Lower Body (Squats) and Core (Plank)
   */
  calculateStrengthScore() {
    let score = 0;

    // Lower Body Strength (Squats - reps)
    const squats = this.data.squats || 0;
    if (squats >= 50) {
      score += 50; // Excellent
    } else if (squats >= 25) {
      score += Math.round((squats / 50) * 50); // Proportional
    } else {
      score += Math.round((squats / 25) * 25); // Starting point
    }

    // Core Strength (Plank Hold - seconds)
    const plankTime = this.data.plankTime || 0;
    if (plankTime >= 120) {
      score += 50; // Excellent (2 min+)
    } else if (plankTime >= 60) {
      score += Math.round((plankTime / 120) * 50); // Proportional
    } else if (plankTime > 0) {
      score += Math.round((plankTime / 60) * 25); // Starting point
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * PILLAR 3: ROM/FLEXIBILITY (12% Weight)
   * Based on Functional Movement Screen (FMS) scoring
   */
  calculateROMScore() {
    const fmsScore = this.data.fmsScore || 0; // 0-21 total
    const ankleScore = this.clamp(this.data.ankleFlexibility / 45, 0, 1) * 25;
    const hipScore = this.clamp((this.data.hipFlexibility + 20) / 70, 0, 1) * 25;
    const fmsComponent = (fmsScore / 21) * 50; // FMS gets 50% weight

    const score = ankleScore + hipScore + fmsComponent;
    return Math.max(0, Math.min(100, score));
  }

  /**
   * PILLAR 4: BALANCE/STABILITY (13% Weight)
   * - Single-leg balance test
   * - FMS balance movements
   */
  calculateBalanceScore() {
    const singleLegBalance = this.data.singleLegBalance || 0;

    let score = 0;
    if (singleLegBalance >= 60) {
      score = 100; // Excellent (60+ seconds)
    } else if (singleLegBalance >= 30) {
      score = Math.round((singleLegBalance / 60) * 100); // Proportional
    } else if (singleLegBalance > 0) {
      score = Math.round((singleLegBalance / 30) * 50); // Basic stability
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * PILLAR 5: MOBILITY (10% Weight)
   * - Ankle dorsiflexion
   * - Hip mobility (sit-and-reach)
   * - Age adjustment
   */
  calculateMobilityScore() {
    const age = this.data.age || 30;
    let score = 0;

    // Ankle Dorsiflexion (0-45°)
    const ankleFlexibility = this.data.ankleFlexibility || 0;
    score += (ankleFlexibility / 45) * 40; // 0-40 points

    // Hip Flexibility (Sit and Reach: -20 to +50 cm)
    const hipFlexibility = this.data.hipFlexibility || 0;
    score += Math.max(0, (hipFlexibility + 20) / 70) * 40; // 0-40 points

    // FMS Deep Squat (0-3)
    const deepSquat = Math.min(3, this.data.fmsDeepSquat || 0);
    score += (deepSquat / 3) * 20; // 0-20 points

    // Age Adjustment: -0.5 points per year over 30
    if (age > 30) {
      score -= (age - 30) * 0.5;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * PILLAR 6: BODY ALIGNMENT (10% Weight)
   * - Q-angle assessment
   * - Foot pronation
   * - Pelvic tilt
   * - Head posture
   * - Scoliosis screening
   */
  calculateAlignmentScore() {
    let score = 100; // Start perfect, deduct for deviations

    // Q-Angle Assessment (ideal: 10-15°)
    const qAngleLeft = this.data.qAngleLeft || 12;
    const qAngleRight = this.data.qAngleRight || 12;
    const qAngleAvg = (qAngleLeft + qAngleRight) / 2;

    if (qAngleAvg < 8 || qAngleAvg > 20) {
      score -= 15; // Significant deviation
    } else if (qAngleAvg < 10 || qAngleAvg > 15) {
      score -= 5; // Minor deviation
    }

    // Foot Pronation (0-30mm navicular drop)
    const navicularDrop = this.data.navicularDrop || 5;
    if (navicularDrop > 15) {
      score -= 15; // Severe overpronation
    } else if (navicularDrop > 10) {
      score -= 8; // Moderate overpronation
    }

    // Body Type (structural consideration, no penalty, informational)
    // Ectomorph: +0, Mesomorph: +5 (generally better alignment), Endomorph: -5

    // Pelvic Tilt
    if (this.data.pelvisTilt === 'anterior' || this.data.pelvisTilt === 'posterior') {
      score -= 10;
    }

    // Forward Head Posture
    if (this.data.forwardHeadPosture === 'moderate') {
      score -= 8;
    } else if (this.data.forwardHeadPosture === 'severe') {
      score -= 15;
    }

    // Scoliosis Screening
    if (this.data.scoliosis === 'yes') {
      score -= 20;
    } else if (this.data.scoliosis === 'minor') {
      score -= 10;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * Determine Grade Based on Score
   */
  getGrade(score) {
    if (score >= 80) {
      return this.grades[100];
    } else if (score >= 70) {
      return this.grades[79];
    } else if (score >= 60) {
      return this.grades[69];
    } else if (score >= 50) {
      return this.grades[59];
    } else {
      return this.grades[0];
    }
  }

  /**
   * Generate Detailed Breakdown with Recommendations
   */
  getBreakdown(total) {
    return {
      score: total,
      pillars: this.pillars,
      recommendations: this.getRecommendations(),
      injuryRisk: this.assessInjuryRisk(),
      trainingFocus: this.determineTrainingFocus()
    };
  }

  /**
   * Assess Injury Risk Based on Pillars
   */
  assessInjuryRisk() {
    let riskFactors = [];
    let riskLevel = 'Low';

    // Balance weakness
    if (this.pillars.balance < 50) {
      riskFactors.push('Weak balance - ankle/knee injury risk');
    }

    // ROM restrictions
    if (this.pillars.rom < 50) {
      riskFactors.push('Limited ROM - muscle strain risk');
    }

    // Alignment issues
    if (this.pillars.alignment < 60) {
      riskFactors.push('Postural misalignment - overuse injury risk');
    }

    // Low overall score
    if (this.pillars.running < 40 || this.pillars.strength < 40) {
      riskFactors.push('Low fitness base - injury vulnerability');
      riskLevel = 'High';
    } else if (riskFactors.length > 1) {
      riskLevel = 'Moderate';
    }

    return {
      level: riskLevel,
      factors: riskFactors
    };
  }

  /**
   * Determine Primary Training Focus
   */
  determineTrainingFocus() {
    const sortedPillars = Object.entries(this.pillars)
      .sort(([, a], [, b]) => a - b)
      .slice(0, 2); // Lowest 2 pillars

    return {
      primary: sortedPillars[0][0],
      secondary: sortedPillars[1][0],
      recommendation: this.getFocusRecommendation(sortedPillars[0][0])
    };
  }

  /**
   * Get Training Recommendations by Pillar
   */
  getRecommendations() {
    const recs = [];

    if (this.pillars.running < 50) {
      recs.push('Build aerobic base: Increase easy run frequency');
    }
    if (this.pillars.strength < 50) {
      recs.push('Develop strength: 2-3x/week resistance training');
    }
    if (this.pillars.rom < 50) {
      recs.push('Improve flexibility: Daily mobility work, yoga 2x/week');
    }
    if (this.pillars.balance < 50) {
      recs.push('Balance training: Single-leg exercises, proprioceptive work');
    }
    if (this.pillars.mobility < 50) {
      recs.push('Enhance mobility: Dynamic stretching, foam rolling');
    }
    if (this.pillars.alignment < 60) {
      recs.push('Postural correction: Physical therapy assessment recommended');
    }

    return recs;
  }

  /**
   * Get specific recommendation for weakest pillar
   */
  getFocusRecommendation(pillar) {
    const recommendations = {
      running: 'Focus on building aerobic capacity with easy runs and tempo work',
      strength: 'Implement structured strength program with compound movements',
      rom: 'Add dynamic and static stretching routines, consider yoga',
      balance: 'Include proprioceptive training and stability exercises',
      mobility: 'Daily mobility drills and foam rolling for joint health',
      alignment: 'Work with physical therapist on postural correction'
    };
    return recommendations[pillar] || 'Continue balanced training approach';
  }

  /**
   * Utility: Parse time string (HH:MM:SS) to minutes
   */
  parseTimeToMinutes(timeStr) {
    const parts = timeStr.split(':').map(Number);
    if (parts.length === 3) {
      return parts[0] * 60 + parts[1] + parts[2] / 60;
    } else if (parts.length === 2) {
      return parts[0] + parts[1] / 60;
    }
    return parseFloat(timeStr);
  }

  /**
   * Utility: Clamp value between min and max
   */
  clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }
}

// Export for use in HTML
if (typeof module !== 'undefined' && module.exports) {
  module.exports = AIFRICalculator;
}
