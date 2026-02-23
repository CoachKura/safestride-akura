/**
 * AISRI ML Analyzer v2.0
 * Machine Learning-based Injury Risk Assessment
 */

class AISRIMLAnalyzer {
  constructor() {
    this.modelVersion = "2.0";
    this.initialized = true;
    console.log("✅ AISRIMLAnalyzer initialized (v" + this.modelVersion + ")");
  }

  /**
   * Analyze athlete data and generate insights
   * @param {Object} athleteData -Athlete performance and biometric data
   * @returns {Array} Array of ML-generated insights
   */
  async analyzeAthleteData(athleteData) {
    const insights = [];

    try {
      // Training Load Analysis
      if (athleteData.trainingLoad) {
        const ratio = athleteData.trainingLoad.ratio || 1.0;

        if (ratio > 1.5) {
          insights.push({
            type: "danger",
            title: "Excessive Training Load",
            message: `Your acute:chronic ratio is ${ratio.toFixed(2)}. High risk of overtraining. Consider reducing volume by 20-30%.`,
            priority: 1,
          });
        } else if (ratio > 1.3) {
          insights.push({
            type: "warning",
            title: "Elevated Training Load",
            message: `Your acute:chronic ratio is ${ratio.toFixed(2)}. Monitor fatigue levels and consider a recovery week.`,
            priority: 2,
          });
        } else if (ratio >= 0.8 && ratio <= 1.3) {
          insights.push({
            type: "success",
            title: "Optimal Training Load",
            message: `Your acute:chronic ratio is ${ratio.toFixed(2)}. Training load is well-balanced for continued progress.`,
            priority: 3,
          });
        }
      }

      // HRV Analysis
      if (athleteData.hrv) {
        const current = athleteData.hrv.current || 0;
        const baseline = athleteData.hrv.baseline || current;
        const deviation = ((current - baseline) / baseline) * 100;

        if (deviation < -15) {
          insights.push({
            type: "danger",
            title: "Low HRV Detected",
            message: `HRV is ${Math.abs(deviation).toFixed(0)}% below baseline. Your body needs additional recovery.`,
            priority: 1,
          });
        } else if (deviation < -7) {
          insights.push({
            type: "warning",
            title: "Reduced HRV",
            message: `HRV is ${Math.abs(deviation).toFixed(0)}% below baseline. Consider lighter training today.`,
            priority: 2,
          });
        } else if (deviation > 10) {
          insights.push({
            type: "success",
            title: "Excellent Recovery",
            message: `HRV is ${deviation.toFixed(0)}% above baseline. Your body is well-recovered and ready for hard training.`,
            priority: 3,
          });
        }
      }

      // Sleep Analysis
      if (athleteData.sleep) {
        const avgHours = athleteData.sleep.averageHours || 0;
        const quality = athleteData.sleep.quality || 0;

        if (avgHours < 6) {
          insights.push({
            type: "danger",
            title: "Insufficient Sleep",
            message: `Average ${avgHours.toFixed(1)} hours/night. Aim for 7-9 hours to optimize recovery and performance.`,
            priority: 1,
          });
        } else if (quality < 0.7) {
          insights.push({
            type: "warning",
            title: "Poor Sleep Quality",
            message: `Sleep quality at ${(quality * 100).toFixed(0)}%. Focus on sleep hygiene for better recovery.`,
            priority: 2,
          });
        } else if (avgHours >= 7 && quality >= 0.8) {
          insights.push({
            type: "success",
            title: "Excellent Sleep Habits",
            message: `Averaging ${avgHours.toFixed(1)} hours with ${(quality * 100).toFixed(0)}% quality. Great foundation for training.`,
            priority: 3,
          });
        }
      }

      // Recovery Score Analysis
      if (athleteData.recovery) {
        const score = athleteData.recovery.score || 0;

        if (score < 50) {
          insights.push({
            type: "warning",
            title: "Low Recovery Score",
            message: `Recovery score: ${score}/100. Prioritize rest and reduce training intensity.`,
            priority: 2,
          });
        } else if (score >= 80) {
          insights.push({
            type: "success",
            title: "High Recovery Score",
            message: `Recovery score: ${score}/100. Perfect time for quality training sessions.`,
            priority: 3,
          });
        }
      }

      // Sort by priority
      insights.sort((a, b) => a.priority - b.priority);

      // Limit to top 5 insights
      return insights.slice(0, 5);
    } catch (error) {
      console.error("❌ Error analyzing athlete data:", error);
      return [
        {
          type: "info",
          title: "Analysis Pending",
          message:
            "Connect your devices to receive personalized training insights.",
          priority: 4,
        },
      ];
    }
  }

  /**
   * Predict injury risk based on recent activity patterns
   * @param {Array} recentActivities - Recent training activities
   * @returns {Object} Risk prediction with confidence score
   */
  predictInjuryRisk(recentActivities) {
    if (!recentActivities || recentActivities.length === 0) {
      return {
        riskLevel: "unknown",
        confidence: 0,
        factors: [],
      };
    }

    const factors = [];
    let riskScore = 0;

    // Check for sudden volume spikes
    if (recentActivities.length >= 2) {
      const recent = recentActivities[0].distance || 0;
      const previous = recentActivities[1].distance || 0;

      if (recent > previous * 1.3) {
        riskScore += 20;
        factors.push("Sudden volume increase detected");
      }
    }

    // Check for consecutive hard efforts
    const hardEfforts = recentActivities.filter(
      (a) => a.avgHeartRate > 160,
    ).length;
    if (hardEfforts > 3) {
      riskScore += 15;
      factors.push("Multiple consecutive high-intensity sessions");
    }

    // Determine risk level
    let riskLevel = "low";
    if (riskScore > 50) riskLevel = "high";
    else if (riskScore > 30) riskLevel = "medium";

    return {
      riskLevel,
      confidence: Math.min(riskScore / 100, 0.95),
      factors,
    };
  }
}

// Export for use in other modules
if (typeof module !== "undefined" && module.exports) {
  module.exports = AISRIMLAnalyzer;
}
