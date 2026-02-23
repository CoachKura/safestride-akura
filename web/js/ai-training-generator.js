/**
 * AI Training Plan Generator v1.0
 * Generates personalized training plans based on AISRI scores
 */

class AITrainingGenerator {
  constructor(aisriScore, athleteData) {
    this.aisriScore = aisriScore;
    this.athleteData = athleteData;
    this.trainingZone = this.determineTrainingZone(aisriScore);

    console.log("✅ AITrainingGenerator initialized:", {
      score: aisriScore,
      zone: this.trainingZone,
    });
  }

  /**
   * Determine primary training zone based on AISRI score
   * @param {Number} score - AISRI score (0-1000)
   * @returns {String} Training zone code
   */
  determineTrainingZone(score) {
    if (score < 400) return "AR"; // Active Recovery
    if (score < 550) return "F"; // Foundation
    if (score < 700) return "EN"; // Endurance
    if (score < 850) return "TH"; // Threshold
    return "P"; // Power
  }

  /**
   * Generate a complete training plan
   * @param {Number} weeks - Number of weeks for the plan
   * @param {String} goal - Training goal (e.g., "5K", "10K", "Half Marathon")
   * @returns {Object} Complete training plan
   */
  generatePlan(weeks = 12, goal = "General Fitness") {
    const plan = {
      name: `${goal} Training Plan`,
      duration: weeks,
      aisriScore: this.aisriScore,
      primaryZone: this.trainingZone,
      weeks: [],
    };

    // Generate weekly structure
    for (let week = 1; week <= weeks; week++) {
      const weekPlan = this.generateWeek(week, weeks, goal);
      plan.weeks.push(weekPlan);
    }

    return plan;
  }

  /**
   * Generate a single week of training
   * @param {Number} weekNumber - Current week number
   * @param {Number} totalWeeks - Total weeks in plan
   * @param {String} goal - Training goal
   * @returns {Object} Week plan with daily workouts
   */
  generateWeek(weekNumber, totalWeeks, goal) {
    const isRecoveryWeek = weekNumber % 4 === 0; // Every 4th week is recovery
    const progressFactor = weekNumber / totalWeeks; // 0.0 to 1.0

    const week = {
      weekNumber,
      theme: isRecoveryWeek
        ? "Recovery"
        : this.getWeekTheme(weekNumber, totalWeeks),
      totalDistance: 0,
      workouts: [],
    };

    // Generate 7 days of workouts
    for (let day = 1; day <= 7; day++) {
      const workout = this.generateDayWorkout(
        day,
        weekNumber,
        isRecoveryWeek,
        progressFactor,
      );
      week.workouts.push(workout);

      if (workout.distance) {
        week.totalDistance += workout.distance;
      }
    }

    return week;
  }

  /**
   * Get week theme based on training phase
   * @param {Number} week - Week number
   * @param {Number} totalWeeks - Total weeks
   * @returns {String} Week theme
   */
  getWeekTheme(week, totalWeeks) {
    const phase = week / totalWeeks;

    if (phase < 0.33) return "Base Building";
    if (phase < 0.66) return "Strength Development";
    if (phase < 0.85) return "Peak Performance";
    return "Taper & Race Prep";
  }

  /**
   * Generate a single day workout
   * @param {Number} day - Day of week (1-7)
   * @param {Number} week - Week number
   * @param {Boolean} isRecoveryWeek - Whether this is a recovery week
   * @param {Number} progressFactor - Progress through plan (0-1)
   * @returns {Object} Workout details
   */
  generateDayWorkout(day, week, isRecoveryWeek, progressFactor) {
    const dayNames = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    // Rest days
    if (day === 3 || day === 7) {
      // Wednesday and Sunday
      return {
        day: dayNames[day - 1],
        type: "rest",
        name: "Rest & Recovery",
        description: "Complete rest or light stretching/yoga",
        duration: 0,
        distance: 0,
        zone: "REST",
      };
    }

    // Recovery week - all easy runs
    if (isRecoveryWeek) {
      return this.generateEasyRun(dayNames[day - 1], Math.max(3, 5 - day));
    }

    // Normal training week structure
    switch (day) {
      case 1: // Monday - Easy run
        return this.generateEasyRun(
          dayNames[0],
          6 + Math.round(progressFactor * 4),
        );

      case 2: // Tuesday - Quality workout
        return this.generateQualityWorkout(dayNames[1], week, progressFactor);

      case 4: // Thursday - Moderate run
        return this.generateModerateRun(
          dayNames[3],
          7 + Math.round(progressFactor * 3),
        );

      case 5: // Friday - Easy run
        return this.generateEasyRun(
          dayNames[4],
          5 + Math.round(progressFactor * 2),
        );

      case 6: // Saturday - Long run
        return this.generateLongRun(dayNames[5], week, progressFactor);

      default:
        return this.generateEasyRun(dayNames[day - 1], 5);
    }
  }

  /**
   * Generate easy recovery run
   */
  generateEasyRun(dayName, distance) {
    return {
      day: dayName,
      type: "easy",
      name: "Easy Recovery Run",
      description: "Easy conversational pace, focus on form and relaxation",
      duration: distance * 6, // Rough estimate: 6 min/km
      distance: distance,
      zone: "AR",
      intensity: "Low",
      hrZone: "Zone 1-2",
    };
  }

  /**
   * Generate moderate paced run
   */
  generateModerateRun(dayName, distance) {
    return {
      day: dayName,
      type: "moderate",
      name: "Steady State Run",
      description: "Comfortable but focused pace, building aerobic capacity",
      duration: distance * 5.5,
      distance: distance,
      zone: "F",
      intensity: "Moderate",
      hrZone: "Zone 2-3",
    };
  }

  /**
   * Generate quality workout based on AISRI zone
   */
  generateQualityWorkout(dayName, week, progressFactor) {
    const workoutTypes = this.getAvailableWorkoutTypes();
    const workoutIndex = (week - 1) % workoutTypes.length;
    const workout = workoutTypes[workoutIndex];

    return {
      day: dayName,
      type: "quality",
      name: workout.name,
      description: workout.description,
      duration: workout.duration,
      distance: workout.distance,
      zone: workout.zone,
      intensity: "High",
      hrZone: workout.hrZone,
      structure: workout.structure,
    };
  }

  /**
   * Generate long run
   */
  generateLongRun(dayName, week, progressFactor) {
    const baseDistance = 10;
    const maxDistance = this.aisriScore >= 700 ? 20 : 15; // Limit based on AISRI
    const distance = Math.min(
      maxDistance,
      Math.round(baseDistance + progressFactor * (maxDistance - baseDistance)),
    );

    return {
      day: dayName,
      type: "long",
      name: "Long Endurance Run",
      description:
        "Build endurance with steady, easy-moderate pace. Stay in comfortable zone.",
      duration: distance * 6.5,
      distance: distance,
      zone: "EN",
      intensity: "Moderate",
      hrZone: "Zone 2",
    };
  }

  /**
   * Get available workout types based on AISRI score
   */
  getAvailableWorkoutTypes() {
    const score = this.aisriScore;

    // Base workouts available to everyone
    const workouts = [
      {
        name: "Fartlek Run",
        description:
          "10 min warm-up, then 6x (2 min moderate, 1 min easy), 10 min cool-down",
        duration: 40,
        distance: 8,
        zone: "F",
        hrZone: "Zone 2-3",
        structure: "Intervals",
      },
    ];

    // Add tempo runs for AISRI >= 550
    if (score >= 550) {
      workouts.push({
        name: "Tempo Run",
        description: "15 min warm-up, 20 min at tempo pace, 10 min cool-down",
        duration: 45,
        distance: 9,
        zone: "EN",
        hrZone: "Zone 3",
        structure: "Continuous",
      });
    }

    // Add threshold workouts for AISRI >= 700
    if (score >= 700) {
      workouts.push({
        name: "Threshold Intervals",
        description:
          "15 min warm-up, 5x (5 min threshold, 2 min rest), 10 min cool-down",
        duration: 60,
        distance: 11,
        zone: "TH",
        hrZone: "Zone 4",
        structure: "Intervals",
      });
    }

    // Add VO2max workouts for AISRI >= 850
    if (score >= 850) {
      workouts.push({
        name: "VO2max Intervals",
        description:
          "20 min warm-up, 6x (3 min hard, 2 min jog), 15 min cool-down",
        duration: 65,
        distance: 10,
        zone: "P",
        hrZone: "Zone 4-5",
        structure: "Intervals",
      });
    }

    return workouts;
  }

  /**
   * Get workout summary for current week
   * @param {Number} weekNumber - Week to summarize
   * @returns {Object} Week summary
   */
  getWeekSummary(weekNumber) {
    const plan = this.generatePlan();
    const week = plan.weeks[weekNumber - 1];

    if (!week) return null;

    const runDays = week.workouts.filter((w) => w.type !== "rest").length;
    const totalDistance = week.totalDistance;
    const qualityDays = week.workouts.filter(
      (w) => w.type === "quality" || w.type === "long",
    ).length;

    return {
      weekNumber,
      theme: week.theme,
      runDays,
      totalDistance,
      qualityDays,
      averagePace: totalDistance > 0 ? "5:30 /km" : "N/A", // Placeholder
      workouts: week.workouts,
    };
  }

  /**
   * Export plan to text format
   * @returns {String} Formatted plan
   */
  exportToText() {
    const plan = this.generatePlan();
    let text = `${plan.name}\n`;
    text += `Duration: ${plan.duration} weeks\n`;
    text += `AISRI Score: ${plan.aisriScore}\n`;
    text += `Primary Zone: ${plan.primaryZone}\n\n`;

    plan.weeks.forEach((week, index) => {
      text += `═══════════════════════════════════════\n`;
      text += `WEEK ${week.weekNumber}: ${week.theme}\n`;
      text += `Total Distance: ${week.totalDistance}km\n`;
      text += `═══════════════════════════════════════\n\n`;

      week.workouts.forEach((workout) => {
        text += `${workout.day}:\n`;
        text += `  ${workout.name} (${workout.zone})\n`;
        text += `  ${workout.description}\n`;
        if (workout.distance > 0) {
          text += `  Distance: ${workout.distance}km | Duration: ${workout.duration} min\n`;
        }
        text += `\n`;
      });

      text += `\n`;
    });

    return text;
  }
}

// Export for use in other modules
if (typeof module !== "undefined" && module.exports) {
  module.exports = AITrainingGenerator;
}
