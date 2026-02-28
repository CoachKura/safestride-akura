// Adaptive Pace Progression Calculator
// Calculates personalized timeline to reach 3:30/km at Zone TH/P
// Respects: Current pace, mileage, AISRI score, experience level

import 'dart:math';

/// Training experience levels
enum ExperienceLevel {
  beginner, // 0-6 months running
  intermediate, // 6-24 months running
  advanced, // 2+ years running
  elite // Competitive runner
}

/// Training phases
enum TrainingPhase {
  foundation, // Build base fitness
  baseBuilding, // Increase endurance
  speedDevelopment, // Add speed work
  thresholdWork, // Lactate threshold training
  powerWork, // High intensity intervals
  goalAchievement // Final push to 3:30/km
}

/// Heart rate training zones
enum HRZone {
  recovery, // AR (Active Recovery) - 50-60% max HR
  foundation, // F (Foundation) - 60-70% max HR
  endurance, // EN (Endurance) - 70-80% max HR
  threshold, // TH (Threshold) - 80-90% max HR
  power // P (Power/Speed) - 90-100% max HR
}

/// Progression plan from current pace to 3:30/km goal
class ProgressionPlan {
  final int totalWeeks;
  final double startPace; // min/km
  final double goalPace; // Always 3.5 (3:30/km)
  final double startMileage; // km/week
  final double goalMileage; // km/week needed for 3:30 pace
  final int startAISRI;
  final int goalAISRI; // Should be 75+ for safe 3:30 pace
  final List<TrainingPhase> phases;
  final List<WeeklyPlan> weeklyPlans;
  final String summary;

  ProgressionPlan({
    required this.totalWeeks,
    required this.startPace,
    required this.goalPace,
    required this.startMileage,
    required this.goalMileage,
    required this.startAISRI,
    required this.goalAISRI,
    required this.phases,
    required this.weeklyPlans,
    required this.summary,
  });

  // Get current week's plan
  WeeklyPlan getCurrentWeek(int weekNumber) {
    if (weekNumber < 1 || weekNumber > totalWeeks) {
      throw ArgumentError('Week number out of range');
    }
    return weeklyPlans[weekNumber - 1];
  }

  // Get phase for specific week
  TrainingPhase getPhaseForWeek(int weekNumber) {
    int accumulated = 0;
    for (int i = 0; i < phases.length; i++) {
      final phaseWeeks = _getPhaseWeeks(phases[i]);
      if (weekNumber <= accumulated + phaseWeeks) {
        return phases[i];
      }
      accumulated += phaseWeeks;
    }
    return phases.last;
  }

  int _getPhaseWeeks(TrainingPhase phase) {
    // Calculate weeks per phase based on total weeks
    final phaseCount = phases.length;
    return (totalWeeks / phaseCount).ceil();
  }
}

/// Weekly training plan
class WeeklyPlan {
  final int weekNumber;
  final TrainingPhase phase;
  final double targetPace; // Easy pace for this week
  final double tempoWorktarget; // Tempo/threshold pace
  final double weeklyMileage;
  final int targetAISRI;
  final List<DailyWorkout> workouts;
  final List<String> focus; // e.g., ['AISRI improvement', 'Mileage build']
  final String notes;

  WeeklyPlan({
    required this.weekNumber,
    required this.phase,
    required this.targetPace,
    required this.tempoWorktarget,
    required this.weeklyMileage,
    required this.targetAISRI,
    required this.workouts,
    required this.focus,
    required this.notes,
  });
}

/// Daily workout
class DailyWorkout {
  final int dayNumber; // 1-7
  final String type; // Run, Strength, ROM, Mobility, Balance, Rest
  final String name;
  final String description;
  final double? distance; // km (for runs)
  final int? duration; // minutes
  final HRZone? zone;
  final List<Interval>? intervals;
  final String? targetPace;
  final String? targetHR;

  DailyWorkout({
    required this.dayNumber,
    required this.type,
    required this.name,
    required this.description,
    this.distance,
    this.duration,
    this.zone,
    this.intervals,
    this.targetPace,
    this.targetHR,
  });
}

/// Workout interval
class Interval {
  final int duration; // minutes
  final HRZone zone;
  final String description;
  final String? pace;

  Interval({
    required this.duration,
    required this.zone,
    required this.description,
    this.pace,
  });
}

/// Main adaptive pace progression calculator
class AdaptivePaceProgressionCalculator {
  // Universal goal: 3:30/km at Zone TH/P
  static const double GOAL_PACE = 3.5; // 3:30 per km
  static const int GOAL_AISRI = 75; // Minimum safe AISRI for 3:30 pace

  /// Calculate personalized progression plan to 3:30/km
  static ProgressionPlan calculateTimeline({
    required double currentPace, // min/km (e.g., 11.0, 6.0, 4.5)
    required double currentMileage, // weekly km
    required int aisriScore,
    required ExperienceLevel experienceLevel,
  }) {
    // 1. Calculate total pace improvement needed
    final paceImprovement = currentPace - GOAL_PACE;

    // 2. Calculate safe weekly pace improvement based on AISRI
    double weeklyImprovement = _getWeeklyPaceImprovement(aisriScore);

    // 3. Calculate weeks needed for pace progression
    int paceWeeks = (paceImprovement / weeklyImprovement).ceil();

    // 4. Calculate weeks needed for AISRI improvement (if needed)
    int aisriWeeks = 0;
    if (aisriScore < GOAL_AISRI) {
      // ~2 points per week improvement with proper protocol training
      aisriWeeks = ((GOAL_AISRI - aisriScore) / 2).ceil();
    }

    // 5. Calculate weeks needed for mileage build-up
    final goalMileage = _getGoalMileage(experienceLevel);
    int mileageWeeks = 0;
    if (currentMileage < goalMileage) {
      // Max 10% weekly mileage increase
      mileageWeeks = _calculateMileageWeeks(currentMileage, goalMileage);
    }

    // 6. Total weeks = max of all constraints
    final totalWeeks = max(max(paceWeeks, aisriWeeks), mileageWeeks);

    // 7. Determine training phases
    final phases = _determinePhases(totalWeeks, aisriScore, experienceLevel);

    // 8. Generate week-by-week plans
    final weeklyPlans = _generateWeeklyPlans(
      totalWeeks: totalWeeks,
      startPace: currentPace,
      startMileage: currentMileage,
      startAISRI: aisriScore,
      phases: phases,
      experienceLevel: experienceLevel,
    );

    // 9. Create summary
    final summary = _generateSummary(
      totalWeeks: totalWeeks,
      startPace: currentPace,
      startMileage: currentMileage,
      startAISRI: aisriScore,
      goalMileage: goalMileage,
    );

    return ProgressionPlan(
      totalWeeks: totalWeeks,
      startPace: currentPace,
      goalPace: GOAL_PACE,
      startMileage: currentMileage,
      goalMileage: goalMileage,
      startAISRI: aisriScore,
      goalAISRI: GOAL_AISRI,
      phases: phases,
      weeklyPlans: weeklyPlans,
      summary: summary,
    );
  }

  /// Get safe weekly pace improvement based on AISRI score
  static double _getWeeklyPaceImprovement(int aisriScore) {
    if (aisriScore >= 75) {
      return 0.15; // 9 seconds per km per week (aggressive)
    } else if (aisriScore >= 60) {
      return 0.10; // 6 seconds per km per week (moderate)
    } else if (aisriScore >= 45) {
      return 0.07; // 4 seconds per km per week (conservative)
    } else {
      return 0.05; // 3 seconds per km per week (very conservative)
    }
  }

  /// Get goal weekly mileage based on experience level
  static double _getGoalMileage(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 40.0; // 40km/week for beginners
      case ExperienceLevel.intermediate:
        return 60.0; // 60km/week for intermediate
      case ExperienceLevel.advanced:
        return 80.0; // 80km/week for advanced
      case ExperienceLevel.elite:
        return 100.0; // 100km/week for elite
    }
  }

  /// Calculate weeks needed for mileage build-up (max 10% per week)
  static int _calculateMileageWeeks(double current, double goal) {
    if (current >= goal) return 0;

    int weeks = 0;
    double mileage = current;

    while (mileage < goal) {
      mileage = mileage * 1.10; // 10% increase
      weeks++;

      // Safety: cap at 52 weeks
      if (weeks > 52) break;
    }

    return weeks;
  }

  /// Determine training phases based on timeline
  static List<TrainingPhase> _determinePhases(
    int totalWeeks,
    int aisriScore,
    ExperienceLevel level,
  ) {
    List<TrainingPhase> phases = [];

    if (aisriScore < 60) {
      // Need AISRI improvement first
      phases.add(TrainingPhase.foundation);
    }

    if (level == ExperienceLevel.beginner) {
      // Beginners need all phases
      phases.addAll([
        TrainingPhase.foundation,
        TrainingPhase.baseBuilding,
        TrainingPhase.speedDevelopment,
        TrainingPhase.thresholdWork,
        TrainingPhase.powerWork,
        TrainingPhase.goalAchievement,
      ]);
    } else if (level == ExperienceLevel.intermediate) {
      // Skip foundation if AISRI is decent
      if (aisriScore >= 60) {
        phases.addAll([
          TrainingPhase.baseBuilding,
          TrainingPhase.speedDevelopment,
          TrainingPhase.thresholdWork,
          TrainingPhase.powerWork,
          TrainingPhase.goalAchievement,
        ]);
      }
    } else {
      // Advanced/elite can skip to speed work
      phases.addAll([
        TrainingPhase.speedDevelopment,
        TrainingPhase.thresholdWork,
        TrainingPhase.powerWork,
        TrainingPhase.goalAchievement,
      ]);
    }

    return phases;
  }

  /// Generate week-by-week training plans
  static List<WeeklyPlan> _generateWeeklyPlans({
    required int totalWeeks,
    required double startPace,
    required double startMileage,
    required int startAISRI,
    required List<TrainingPhase> phases,
    required ExperienceLevel experienceLevel,
  }) {
    List<WeeklyPlan> plans = [];

    // Calculate progression rates
    final pacePerWeek = (startPace - GOAL_PACE) / totalWeeks;
    final mileagePerWeek =
        (_getGoalMileage(experienceLevel) - startMileage) / totalWeeks;
    final aisriPerWeek = (GOAL_AISRI - startAISRI) / totalWeeks;

    for (int week = 1; week <= totalWeeks; week++) {
      // Calculate targets for this week
      final targetPace = startPace - (pacePerWeek * week);
      final tempoTarget = targetPace - 0.5; // 30 seconds faster than easy pace
      final weeklyMileage = startMileage + (mileagePerWeek * week);
      final targetAISRI = (startAISRI + (aisriPerWeek * week)).round();

      // Determine phase
      final phase = _getPhaseForWeek(week, totalWeeks, phases);

      // Generate workouts for this week
      final workouts = _generateWeeklyWorkouts(
        week: week,
        phase: phase,
        targetPace: targetPace,
        tempoTarget: tempoTarget,
        weeklyMileage: weeklyMileage,
        aisriScore: targetAISRI,
        experienceLevel: experienceLevel,
      );

      // Determine focus areas
      final focus = _getWeekFocus(phase, targetAISRI);

      // Generate notes
      final notes = _generateWeekNotes(week, phase, targetPace, targetAISRI);

      plans.add(WeeklyPlan(
        weekNumber: week,
        phase: phase,
        targetPace: targetPace,
        tempoWorktarget: tempoTarget,
        weeklyMileage: weeklyMileage,
        targetAISRI: targetAISRI,
        workouts: workouts,
        focus: focus,
        notes: notes,
      ));
    }

    return plans;
  }

  /// Get phase for specific week number
  static TrainingPhase _getPhaseForWeek(
    int week,
    int totalWeeks,
    List<TrainingPhase> phases,
  ) {
    final weeksPerPhase = totalWeeks / phases.length;
    final phaseIndex = ((week - 1) / weeksPerPhase).floor();
    return phases[min(phaseIndex, phases.length - 1)];
  }

  /// Generate daily workouts for a week
  static List<DailyWorkout> _generateWeeklyWorkouts({
    required int week,
    required TrainingPhase phase,
    required double targetPace,
    required double tempoTarget,
    required double weeklyMileage,
    required int aisriScore,
    required ExperienceLevel experienceLevel,
  }) {
    List<DailyWorkout> workouts = [];

    // Calculate daily distances (7 days)
    final avgDistance =
        weeklyMileage / 5; // 5 running days, 2 rest/cross-training

    // Day 1: Easy run
    workouts.add(DailyWorkout(
      dayNumber: 1,
      type: 'Run',
      name: 'Easy Recovery Run',
      description: 'Conversational pace, focus on form',
      distance: avgDistance * 0.8,
      duration: ((avgDistance * 0.8) * targetPace).round(),
      zone: HRZone.foundation,
      targetPace: '${_formatPace(targetPace)}',
      targetHR: _getHRTarget(HRZone.foundation),
    ));

    // Day 2: Strength training
    workouts.add(_generateStrengthWorkout(2, aisriScore));

    // Day 3: Tempo/Speed work (depends on phase)
    if (phase == TrainingPhase.foundation ||
        phase == TrainingPhase.baseBuilding) {
      workouts.add(DailyWorkout(
        dayNumber: 3,
        type: 'Run',
        name: 'Easy Run',
        description: 'Build aerobic base',
        distance: avgDistance,
        duration: (avgDistance * targetPace).round(),
        zone: HRZone.foundation,
        targetPace: '${_formatPace(targetPace)}',
        targetHR: _getHRTarget(HRZone.foundation),
      ));
    } else {
      workouts.add(_generateSpeedWorkout(3, phase, tempoTarget, avgDistance));
    }

    // Day 4: ROM/Mobility
    workouts.add(_generateROMWorkout(4, aisriScore));

    // Day 5: Long run
    workouts.add(DailyWorkout(
      dayNumber: 5,
      type: 'Run',
      name: 'Long Run',
      description: 'Build endurance, maintain easy pace',
      distance: avgDistance * 1.5,
      duration: ((avgDistance * 1.5) * targetPace).round(),
      zone: HRZone.endurance,
      targetPace: '${_formatPace(targetPace + 0.25)}', // Slightly slower
      targetHR: _getHRTarget(HRZone.endurance),
    ));

    // Day 6: Balance/Core
    workouts.add(_generateBalanceWorkout(6, aisriScore));

    // Day 7: Rest or active recovery
    workouts.add(DailyWorkout(
      dayNumber: 7,
      type: 'Rest',
      name: 'Active Rest Day',
      description: 'Light mobility work or complete rest',
      duration: 20,
    ));

    return workouts;
  }

  /// Generate strength workout based on AISRI needs
  static DailyWorkout _generateStrengthWorkout(int day, int aisriScore) {
    return DailyWorkout(
      dayNumber: day,
      type: 'Strength',
      name: 'Runner Strength Training',
      description: 'Lower body + core stability',
      duration: 45,
    );
  }

  /// Generate speed workout based on phase
  static DailyWorkout _generateSpeedWorkout(
    int day,
    TrainingPhase phase,
    double tempoTarget,
    double distance,
  ) {
    if (phase == TrainingPhase.speedDevelopment) {
      return DailyWorkout(
        dayNumber: day,
        type: 'Run',
        name: 'Tempo Run',
        description: 'Comfortably hard pace',
        distance: distance,
        duration: (distance * tempoTarget).round(),
        zone: HRZone.endurance,
        targetPace: '${_formatPace(tempoTarget)}',
        targetHR: _getHRTarget(HRZone.endurance),
      );
    } else if (phase == TrainingPhase.thresholdWork) {
      return DailyWorkout(
        dayNumber: day,
        type: 'Run',
        name: 'Threshold Intervals',
        description: 'Lactate threshold training',
        distance: distance,
        duration: (distance * tempoTarget).round(),
        zone: HRZone.threshold,
        intervals: [
          Interval(duration: 10, zone: HRZone.recovery, description: 'Warm-up'),
          Interval(
              duration: 5,
              zone: HRZone.threshold,
              description: 'Hard',
              pace: _formatPace(tempoTarget)),
          Interval(duration: 2, zone: HRZone.recovery, description: 'Recovery'),
          Interval(
              duration: 5,
              zone: HRZone.threshold,
              description: 'Hard',
              pace: _formatPace(tempoTarget)),
          Interval(
              duration: 10, zone: HRZone.recovery, description: 'Cool-down'),
        ],
        targetHR: _getHRTarget(HRZone.threshold),
      );
    } else {
      // Power work
      return DailyWorkout(
        dayNumber: day,
        type: 'Run',
        name: 'Power Intervals',
        description: '3:30/km goal pace work!',
        distance: distance,
        duration: (distance * 3.5).round(),
        zone: HRZone.power,
        intervals: [
          Interval(duration: 10, zone: HRZone.recovery, description: 'Warm-up'),
          Interval(
              duration: 2,
              zone: HRZone.power,
              description: '400m @ 3:30/km',
              pace: '3:30'),
          Interval(
              duration: 2, zone: HRZone.recovery, description: 'Recovery jog'),
          Interval(
              duration: 2,
              zone: HRZone.power,
              description: '400m @ 3:30/km',
              pace: '3:30'),
          Interval(
              duration: 10, zone: HRZone.recovery, description: 'Cool-down'),
        ],
        targetPace: '3:30/km',
        targetHR: _getHRTarget(HRZone.power),
      );
    }
  }

  /// Generate ROM workout
  static DailyWorkout _generateROMWorkout(int day, int aisriScore) {
    return DailyWorkout(
      dayNumber: day,
      type: 'ROM',
      name: 'Range of Motion',
      description: 'Hip, ankle, hamstring flexibility',
      duration: 30,
    );
  }

  /// Generate balance workout
  static DailyWorkout _generateBalanceWorkout(int day, int aisriScore) {
    return DailyWorkout(
      dayNumber: day,
      type: 'Balance',
      name: 'Balance & Proprioception',
      description: 'Single-leg exercises, stability work',
      duration: 30,
    );
  }

  /// Get week focus areas
  static List<String> _getWeekFocus(TrainingPhase phase, int aisriScore) {
    List<String> focus = [];

    if (aisriScore < 60) {
      focus.add('AISRI improvement (priority!)');
    }

    switch (phase) {
      case TrainingPhase.foundation:
        focus.addAll(
            ['Build aerobic base', 'Injury prevention', 'Form development']);
        break;
      case TrainingPhase.baseBuilding:
        focus.addAll([
          'Increase mileage safely',
          'Strengthen weak pillars',
          '10% weekly increase max'
        ]);
        break;
      case TrainingPhase.speedDevelopment:
        focus.addAll(['Add tempo runs', 'Improve pace', 'Maintain AISRI']);
        break;
      case TrainingPhase.thresholdWork:
        focus.addAll(
            ['Lactate threshold', 'Threshold intervals', 'Push pace down']);
        break;
      case TrainingPhase.powerWork:
        focus
            .addAll(['3:30/km intervals', 'Zone P work', 'Goal pace practice']);
        break;
      case TrainingPhase.goalAchievement:
        focus.addAll(['Sustain 3:30/km', 'Race prep', 'Maintain fitness']);
        break;
    }

    return focus;
  }

  /// Generate week notes
  static String _generateWeekNotes(
    int week,
    TrainingPhase phase,
    double targetPace,
    int aisriScore,
  ) {
    final remaining = (targetPace - GOAL_PACE).abs();
    final remainingFormatted = _formatPace(remaining);

    return 'Week $week: ${phase.toString().split('.').last}. '
        'Target pace: ${_formatPace(targetPace)}. '
        'AISRI target: $aisriScore. '
        '${remaining > 1.0 ? "Still $remainingFormatted from goal" : "Getting close to 3:30/km goal!"}';
  }

  /// Generate overall summary
  static String _generateSummary({
    required int totalWeeks,
    required double startPace,
    required double startMileage,
    required int startAISRI,
    required double goalMileage,
  }) {
    final months = (totalWeeks / 4.33).ceil();

    return '''
Your personalized path to 3:30/km at Zone TH/P:

📊 Timeline: $totalWeeks weeks (${months} months)

🏃 Pace Journey:
  • Starting: ${_formatPace(startPace)}
  • Goal: 3:30/km ✓
  • Improvement: ${_formatPace(startPace - GOAL_PACE)}

📏 Mileage Build:
  • Starting: ${startMileage.toStringAsFixed(0)} km/week
  • Goal: ${goalMileage.toStringAsFixed(0)} km/week
  • Max 10% weekly increase (safe progression)

🎯 AISRI Journey:
  • Starting: $startAISRI
  • Goal: $GOAL_AISRI+ (minimum for 3:30 pace)
  • ~2 points per week improvement

✅ Protocol Balance:
  • Running: 5 days/week
  • Strength: 2 days/week
  • ROM: 3 days/week
  • Mobility: Daily
  • Balance: 2 days/week

🏆 Result: Safe, injury-free progression to 3:30/km at Zone TH/P!
''';
  }

  /// Format pace as MM:SS
  static String _formatPace(double pace) {
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
  }

  /// Get HR target range for zone
  static String _getHRTarget(HRZone zone) {
    // Based on 220 - age formula
    // These are percentages, actual calculation needs athlete age
    switch (zone) {
      case HRZone.recovery:
        return '50-60% max HR';
      case HRZone.foundation:
        return '60-70% max HR';
      case HRZone.endurance:
        return '70-80% max HR';
      case HRZone.threshold:
        return '80-90% max HR';
      case HRZone.power:
        return '90-100% max HR';
    }
  }
}
