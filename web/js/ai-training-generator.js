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

/**
 * AI Training Program Generator v2.0
 * Advanced training plan generator with AISRI integration
 */
class AITrainingProgramGenerator {
  constructor(aisriEngine) {
    this.aisriEngine = aisriEngine;
    console.log("✅ AITrainingProgramGenerator initialized (v2.0)");
  }

  /**
   * Generate a comprehensive 12-week training program
   * @param {Object} params - Athlete parameters
   * @returns {Object} Complete training program
   */
  generateProgram(params) {
    const {
      name = "Athlete",
      age = 30,
      restingHR = 60,
      aisriScore = 700,
      pillars = {},
      allowedZones = [],
      hrZones = [],
      totalDistance = 30,
      trainingPhase = "Foundation",
    } = params;

    console.log("🏃 Generating training program for:", name);
    console.log("   AISRI Score:", aisriScore);
    console.log("   Training Phase:", trainingPhase);
    console.log("   Allowed Zones:", allowedZones);

    const program = {
      athleteName: name,
      programName: `${name}'s 12-Week Training Program`,
      aisriScore,
      trainingPhase,
      allowedZones,
      hrZones,
      totalWeeks: 12,
      weeks: [],
    };

    // Generate 12 weeks
    for (let week = 1; week <= 12; week++) {
      const weekPlan = this._generateWeek(week, {
        aisriScore,
        allowedZones,
        hrZones,
        totalDistance,
        trainingPhase,
        pillars,
      });
      program.weeks.push(weekPlan);
    }

    return program;
  }

  /**
   * Generate a single week of training
   * @private
   */
  _generateWeek(weekNumber, params) {
    const { aisriScore, allowedZones, hrZones, totalDistance, trainingPhase } =
      params;
    const isRecoveryWeek = weekNumber % 4 === 0;

    // Calculate weekly distance (progressive overload)
    const baseDistance = totalDistance;
    const progressFactor = 1 + weekNumber * 0.03; // 3% per week
    const weeklyDistance = isRecoveryWeek
      ? baseDistance * 0.7
      : baseDistance * progressFactor;

    const week = {
      weekNumber,
      theme: isRecoveryWeek
        ? "Recovery & Consolidation"
        : this._getWeekTheme(weekNumber, trainingPhase),
      totalDistance: Math.round(weeklyDistance * 10) / 10,
      workouts: [],
    };

    // Generate 7 days
    for (let day = 1; day <= 7; day++) {
      const workout = this._generateDayWorkout(day, weekNumber, {
        isRecoveryWeek,
        allowedZones,
        hrZones,
        weeklyDistance,
        aisriScore,
      });
      week.workouts.push(workout);
    }

    return week;
  }

  /**
   * Get week theme based on progression
   * @private
   */
  _getWeekTheme(weekNumber, trainingPhase) {
    if (weekNumber <= 3) return "Foundation Building";
    if (weekNumber <= 6) return "Base Endurance";
    if (weekNumber <= 9) return "Progressive Intensity";
    return "Peak Training";
  }

  /**
   * Generate a single day workout
   * @private
   */
  _generateDayWorkout(day, weekNumber, params) {
    const { isRecoveryWeek, allowedZones, hrZones, weeklyDistance, aisriScore } =
      params;

    const dayNames = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    const dayName = dayNames[day - 1];

    // Rest days: Tuesday, Thursday, Sunday
    if ([2, 4, 7].includes(day) && !isRecoveryWeek) {
      return {
        day: dayName,
        type: "rest",
        name: "Rest Day",
        description: "Complete rest or light stretching/yoga",
        distance: 0,
        duration: 0,
        zone: "AR",
        hrRange: "N/A",
      };
    }

    // Recovery week: more rest days
    if (isRecoveryWeek && [2, 3, 4, 6, 7].includes(day)) {
      return {
        day: dayName,
        type: "rest",
        name: "Rest Day",
        description: "Recovery week - prioritize rest",
        distance: 0,
        duration: 0,
        zone: "AR",
        hrRange: "N/A",
      };
    }

    // Determine workout type based on day and allowed zones
    return this._createWorkout(day, weekNumber, {
      dayName,
      allowedZones,
      hrZones,
      weeklyDistance,
      isRecoveryWeek,
      aisriScore,
    });
  }

  /**
   * Create a specific workout
   * @private
   */
  _createWorkout(day, weekNumber, params) {
    const { dayName, allowedZones, hrZones, weeklyDistance, isRecoveryWeek, aisriScore } =
      params;

    // Determine workout type based on day
    let workoutType;
    if (day === 1) workoutType = "easy"; // Monday: Easy
    else if (day === 3) workoutType = "tempo"; // Wednesday: Quality
    else if (day === 5) workoutType = "intervals"; // Friday: Intervals
    else if (day === 6) workoutType = "long"; // Saturday: Long run
    else workoutType = "easy"; // Default

    // If recovery week, make everything easy
    if (isRecoveryWeek) workoutType = "easy";

    // Get workout details based on type
    return this._getWorkoutDetails(workoutType, {
      dayName,
      allowedZones,
      hrZones,
      weeklyDistance,
      aisriScore,
      weekNumber,
    });
  }

  /**
   * Get workout details based on type
   * @private
   */
  _getWorkoutDetails(type, params) {
    const { dayName, allowedZones, hrZones, weeklyDistance, aisriScore, weekNumber } =
      params;

    // Base distances
    const easyDistance = weeklyDistance * 0.15;
    const tempoDistance = weeklyDistance * 0.12;
    const intervalDistance = weeklyDistance * 0.10;
    const longDistance = weeklyDistance * 0.30;

    switch (type) {
      case "easy":
        return {
          day: dayName,
          type: "easy",
          name: "Easy Run",
          description:
            "Comfortable, conversational pace. Focus on building aerobic base.",
          distance: Math.round(easyDistance * 10) / 10,
          duration: Math.round((easyDistance / 0.15) * 60), // ~9 min/km
          zone: "F",
          hrRange: this._getHRRange(hrZones, "F"),
        };

      case "tempo":
        // Check if threshold zones are unlocked
        const canDoTempo =
          allowedZones.includes("TH") || allowedZones.includes("T");
        return {
          day: dayName,
          type: "tempo",
          name: canDoTempo ? "Tempo Run" : "Steady Pace Run",
          description: canDoTempo
            ? "Comfortably hard pace (10K race effort). Build lactate threshold."
            : "Steady, sustained effort. Working towards threshold pace.",
          distance: Math.round(tempoDistance * 10) / 10,
          duration: Math.round((tempoDistance / 0.18) * 60), // ~5:30 min/km
          zone: canDoTempo ? "TH" : "EN",
          hrRange: this._getHRRange(hrZones, canDoTempo ? "TH" : "EN"),
        };

      case "intervals":
        // Check if power/speed zones are unlocked
        const canDoIntervals =
          allowedZones.includes("P") || allowedZones.includes("SP");
        return {
          day: dayName,
          type: "intervals",
          name: canDoIntervals ? "Interval Training" : "Fartlek Run",
          description: canDoIntervals
            ? "High-intensity intervals: 6x800m @ 5K pace (3min recovery)"
            : "Variable pace run with tempo surges (not full intensity)",
          distance: Math.round(intervalDistance * 10) / 10,
          duration: Math.round((intervalDistance / 0.16) * 60), // ~6 min/km avg
          zone: canDoIntervals ? "P" : "EN",
          hrRange: this._getHRRange(hrZones, canDoIntervals ? "P" : "EN"),
        };

      case "long":
        return {
          day: dayName,
          type: "long",
          name: "Long Run",
          description:
            "Extended run at easy pace. Build endurance and mental toughness.",
          distance: Math.round(longDistance * 10) / 10,
          duration: Math.round((longDistance / 0.14) * 60), // ~8:30 min/km
          zone: "EN",
          hrRange: this._getHRRange(hrZones, "EN"),
        };

      default:
        return {
          day: dayName,
          type: "easy",
          name: "Easy Run",
          description: "Comfortable recovery pace",
          distance: Math.round(easyDistance * 10) / 10,
          duration: Math.round((easyDistance / 0.15) * 60),
          zone: "F",
          hrRange: this._getHRRange(hrZones, "F"),
        };
    }
  }

  /**
   * Get HR range for a specific zone
   * @private
   */
  _getHRRange(hrZones, zoneCode) {
    if (!hrZones || hrZones.length === 0) return "N/A";

    // Map zone codes to HR zone indices
    const zoneMap = {
      AR: 0, // Active Recovery
      F: 1, // Foundation
      EN: 2, // Endurance
      TH: 3, // Threshold
      T: 3, // Threshold (alias)
      P: 4, // Power
      SP: 4, // Speed (use Power zone)
    };

    const zoneIndex = zoneMap[zoneCode] || 1;
    const zone = hrZones[zoneIndex];

    if (!zone) return "N/A";
    return `${zone.min}-${zone.max} bpm`;
  }
}

// Export for use in other modules
if (typeof module !== "undefined" && module.exports) {
  module.exports = { AITrainingGenerator, AITrainingProgramGenerator };
}
