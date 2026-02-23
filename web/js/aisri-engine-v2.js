/**
 * AISRI Engine v2.0
 * Core Injury Risk Scoring Engine
 * Akura Intelligent Safe Running Index
 */

class AISRIEngine {
  constructor() {
    this.version = "2.0";
    this.initialized = true;

    // Pillar weights (must sum to 1.0)
    this.weights = {
      running: 0.4, // 40% - Running performance and metrics
      strength: 0.15, // 15% - Muscular strength
      rom: 0.12, // 12% - Range of Motion
      balance: 0.13, // 13% - Balance and stability
      alignment: 0.1, // 10% - Body alignment
      mobility: 0.1, // 10% - Dynamic mobility
    };

    console.log("✅ AISRIEngine initialized (v" + this.version + ")");
  }

  /**
   * Calculate AISRI score from pillar values
   * @param {Object} pillars - Object containing pillar scores (0-100 each)
   * @returns {Object} AISRI score and analysis
   */
  calculateAISRI(pillars) {
    try {
      // Validate pillars
      const requiredPillars = [
        "running",
        "strength",
        "rom",
        "balance",
        "alignment",
        "mobility",
      ];
      for (const pillar of requiredPillars) {
        if (!pillars.hasOwnProperty(pillar)) {
          throw new Error(`Missing pillar: ${pillar}`);
        }
      }

      // Calculate weighted score (0-1000 scale)
      let totalScore = 0;
      for (const [pillar, weight] of Object.entries(this.weights)) {
        const pillarScore = Math.max(0, Math.min(100, pillars[pillar])); // Clamp 0-100
        totalScore += pillarScore * weight * 10; // Scale to 0-1000
      }

      // Round to integer
      const score = Math.round(totalScore);

      // Determine risk category
      const category = this.getCategory(score);

      // Determine allowed training zones
      const allowedZones = this.getAllowedZones(score);

      // Calculate HR zones
      const hrZones = this.calculateHRZones(pillars.age || 30);

      // Identify weak pillars (below 60)
      const weakPillars = Object.entries(pillars)
        .filter(([key, value]) => requiredPillars.includes(key) && value < 60)
        .map(([key]) => key);

      // Generate recommendations
      const recommendations = this.generateRecommendations(score, weakPillars);

      return {
        score,
        category,
        allowedZones,
        hrZones,
        weakPillars,
        recommendations,
        pillarContributions: this.calculatePillarContributions(pillars),
      };
    } catch (error) {
      console.error("❌ Error calculating AISRI:", error);
      return {
        score: 0,
        category: "Unknown",
        allowedZones: ["AR"],
        hrZones: this.calculateHRZones(30),
        weakPillars: [],
        recommendations: [
          "Unable to calculate AISRI score. Please check input data.",
        ],
        pillarContributions: {},
      };
    }
  }

  /**
   * Get risk category from score
   * @param {Number} score - AISRI score (0-1000)
   * @returns {String} Risk category
   */
  getCategory(score) {
    if (score >= 850) return "Very Low Risk";
    if (score >= 700) return "Low Risk";
    if (score >= 550) return "Medium Risk";
    if (score >= 400) return "High Risk";
    return "Critical Risk";
  }

  /**
   * Determine allowed training zones based on score
   * @param {Number} score - AISRI score (0-1000)
   * @returns {Array} Array of allowed zone codes
   */
  getAllowedZones(score) {
    const zones = ["AR"]; // Active Recovery always allowed

    if (score >= 300) zones.push("F"); // Foundation
    if (score >= 450) zones.push("EN"); // Endurance
    if (score >= 600) zones.push("TH"); // Threshold
    if (score >= 750) zones.push("P"); // Power
    if (score >= 900) zones.push("SP"); // Speed

    return zones;
  }

  /**
   * Calculate heart rate training zones
   * @param {Number} age - Athlete age
   * @returns {Object} HR zones
   */
  calculateHRZones(age) {
    const maxHR = 220 - age;

    return {
      zone1: { min: Math.round(maxHR * 0.5), max: Math.round(maxHR * 0.6) },
      zone2: { min: Math.round(maxHR * 0.6), max: Math.round(maxHR * 0.7) },
      zone3: { min: Math.round(maxHR * 0.7), max: Math.round(maxHR * 0.8) },
      zone4: { min: Math.round(maxHR * 0.8), max: Math.round(maxHR * 0.9) },
      zone5: { min: Math.round(maxHR * 0.9), max: maxHR },
    };
  }

  /**
   * Calculate individual pillar contributions to total score
   * @param {Object} pillars - Pillar scores
   * @returns {Object} Contribution of each pillar
   */
  calculatePillarContributions(pillars) {
    const contributions = {};

    for (const [pillar, weight] of Object.entries(this.weights)) {
      if (pillars.hasOwnProperty(pillar)) {
        contributions[pillar] = Math.round(pillars[pillar] * weight * 10);
      }
    }

    return contributions;
  }

  /**
   * Generate personalized recommendations
   * @param {Number} score - AISRI score
   * @param {Array} weakPillars - List of weak pillars
   * @returns {Array} Recommendations
   */
  generateRecommendations(score, weakPillars) {
    const recommendations = [];

    // Score-based recommendations
    if (score < 400) {
      recommendations.push(
        "Focus on building a strong foundation with easy runs and strength training",
      );
      recommendations.push(
        "Limit high-intensity workouts until your AISRI score improves",
      );
    } else if (score < 600) {
      recommendations.push(
        "Continue building your aerobic base with consistent easy runs",
      );
      recommendations.push("Add 1-2 moderate intensity sessions per week");
    } else if (score < 800) {
      recommendations.push(
        "You can safely incorporate threshold and tempo workouts",
      );
      recommendations.push("Consider adding speed work 1x per week");
    } else {
      recommendations.push(
        "Excellent condition! You can handle high-intensity training",
      );
      recommendations.push(
        "Focus on race-specific workouts and maintaining your base",
      );
    }

    // Pillar-specific recommendations
    const pillarAdvice = {
      running: "Increase weekly mileage gradually (max 10% per week)",
      strength:
        "Add 2-3 strength training sessions per week focusing on lower body",
      rom: "Include daily stretching routine focusing on hamstrings, hip flexors, and calves",
      balance: "Add single-leg exercises and proprioception drills 3x per week",
      alignment:
        "Consider gait analysis and corrective exercises from a physical therapist",
      mobility: "Dynamic warm-up before runs and mobility work 4-5x per week",
    };

    weakPillars.forEach((pillar) => {
      if (pillarAdvice[pillar]) {
        recommendations.push(
          `⚠️ ${pillar.toUpperCase()}: ${pillarAdvice[pillar]}`,
        );
      }
    });

    return recommendations.slice(0, 6); // Limit to 6 recommendations
  }

  /**
   * Calculate training readiness based on recent metrics
   * @param {Object} metrics - Recent training metrics (HRV, sleep, etc.)
   * @returns {Object} Readiness score and recommendation
   */
  calculateReadiness(metrics) {
    let readinessScore = 100;
    const factors = [];

    if (metrics.hrv) {
      const hrvDeviation =
        ((metrics.hrv.current - metrics.hrv.baseline) / metrics.hrv.baseline) *
        100;
      if (hrvDeviation < -15) {
        readinessScore -= 30;
        factors.push("Low HRV");
      } else if (hrvDeviation < -7) {
        readinessScore -= 15;
        factors.push("Reduced HRV");
      }
    }

    if (metrics.sleep && metrics.sleep.averageHours < 6) {
      readinessScore -= 20;
      factors.push("Insufficient sleep");
    }

    if (metrics.trainingLoad && metrics.trainingLoad.ratio > 1.5) {
      readinessScore -= 25;
      factors.push("High training load");
    }

    if (metrics.recovery && metrics.recovery.score < 50) {
      readinessScore -= 15;
      factors.push("Low recovery");
    }

    const recommendation =
      readinessScore >= 80
        ? "Go hard"
        : readinessScore >= 60
          ? "Moderate intensity"
          : readinessScore >= 40
            ? "Easy training only"
            : "Rest day recommended";

    return {
      score: Math.max(0, readinessScore),
      recommendation,
      factors,
    };
  }
}

// Export for use in other modules
if (typeof module !== "undefined" && module.exports) {
  module.exports = AISRIEngine;
}
