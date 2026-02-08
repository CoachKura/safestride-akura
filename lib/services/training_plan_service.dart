// Training Plan Generator Service
// Creates personalized 4-week training plans based on Strava activity data
// Uses athlete's fitness level, recent performance, and goals

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_step.dart';

class TrainingPlanService {
  final _supabase = Supabase.instance.client;

  /// Analyze athlete's Strava data to determine fitness level
  Future<AthleteProfile> analyzeAthleteProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Get last 30 days of activities
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final activities = await _supabase
        .from('gps_activities')
        .select()
        .eq('user_id', userId)
        .gte('start_date', thirtyDaysAgo.toIso8601String())
        .order('start_date', ascending: false);

    if (activities.isEmpty) {
      return AthleteProfile(
        level: FitnessLevel.beginner,
        weeklyDistance: 0,
        avgPace: 0,
        weeklyRuns: 0,
        longestRun: 0,
        avgHeartRate: 0,
      );
    }

    // Calculate metrics
    double totalDistance = 0;
    double totalTime = 0;
    double maxDistance = 0;
    double totalHeartRate = 0;
    int hrCount = 0;
    int runCount = activities.length;

    for (var activity in activities) {
      final distance = (activity['distance'] ?? 0).toDouble();
      final time = (activity['moving_time'] ?? 0).toDouble();
      final hr = activity['average_heartrate'];

      totalDistance += distance;
      totalTime += time;
      if (distance > maxDistance) maxDistance = distance;
      if (hr != null) {
        totalHeartRate += hr;
        hrCount++;
      }
    }

    final weeklyDistance =
        (totalDistance / 4) / 1000; // km per week (30 days � 4 weeks)
    final avgPace =
        totalTime > 0 ? (totalTime / 60) / (totalDistance / 1000) : 0; // min/km
    final avgHr = hrCount > 0 ? totalHeartRate / hrCount : 0;
    final weeklyRuns = runCount / 4;

    // Determine fitness level based on weekly distance
    FitnessLevel level;
    if (weeklyDistance < 15) {
      level = FitnessLevel.beginner;
    } else if (weeklyDistance < 30) {
      level = FitnessLevel.intermediate;
    } else if (weeklyDistance < 50) {
      level = FitnessLevel.advanced;
    } else {
      level = FitnessLevel.elite;
    }

    return AthleteProfile(
      level: level,
      weeklyDistance: weeklyDistance,
      avgPace: avgPace.toDouble(),
      weeklyRuns: weeklyRuns,
      longestRun: (maxDistance / 1000).toDouble(),
      avgHeartRate: avgHr.toDouble(),
    );
  }

  /// Generate a personalized 4-week training plan
  Future<TrainingPlan> generateTrainingPlan({
    required TrainingGoal goal,
    DateTime? raceDate,
    double? targetDistance,
  }) async {
    final profile = await analyzeAthleteProfile();

    final plan = TrainingPlan(
      name: _getPlanName(goal),
      goal: goal,
      startDate: _getNextMonday(),
      weeks: [],
      athleteProfile: profile,
    );

    // Generate 4 weeks of training
    for (int week = 1; week <= 4; week++) {
      final weekPlan = _generateWeek(
        week: week,
        profile: profile,
        goal: goal,
        isRecoveryWeek: week == 4, // Week 4 is recovery/taper
        targetDistance: targetDistance,
      );
      plan.weeks.add(weekPlan);
    }

    return plan;
  }

  String _getPlanName(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.general5k:
        return '5K Training Plan';
      case TrainingGoal.general10k:
        return '10K Training Plan';
      case TrainingGoal.halfMarathon:
        return 'Half Marathon Training';
      case TrainingGoal.marathon:
        return 'Marathon Training';
      case TrainingGoal.speedImprovement:
        return 'Speed Improvement Plan';
      case TrainingGoal.enduranceBase:
        return 'Endurance Base Building';
      case TrainingGoal.maintenance:
        return 'Fitness Maintenance';
    }
  }

  DateTime _getNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    return DateTime(now.year, now.month,
        now.day + (daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }

  TrainingWeek _generateWeek({
    required int week,
    required AthleteProfile profile,
    required TrainingGoal goal,
    required bool isRecoveryWeek,
    double? targetDistance,
  }) {
    final baseDistance = _getWeeklyBaseDistance(profile, goal);
    final progressionFactor = isRecoveryWeek ? 0.7 : (1.0 + (week - 1) * 0.1);
    final weekDistance = baseDistance * progressionFactor;

    final days = <TrainingDay>[];
    final weekStart = _getNextMonday().add(Duration(days: (week - 1) * 7));

    // Generate workouts for each day based on goal
    final schedule = _getWeeklySchedule(profile.level, goal, isRecoveryWeek);

    for (int day = 0; day < 7; day++) {
      final date = weekStart.add(Duration(days: day));
      final workoutType = schedule[day];

      if (workoutType == null) {
        days.add(TrainingDay(
          date: date,
          dayOfWeek: _getDayName(day),
          workout: null,
          isRestDay: true,
        ));
      } else {
        days.add(TrainingDay(
          date: date,
          dayOfWeek: _getDayName(day),
          workout: _createWorkout(workoutType, profile, weekDistance, goal),
          isRestDay: false,
        ));
      }
    }

    return TrainingWeek(
      weekNumber: week,
      theme: _getWeekTheme(week, goal, isRecoveryWeek),
      totalDistance: weekDistance,
      days: days,
    );
  }

  double _getWeeklyBaseDistance(AthleteProfile profile, TrainingGoal goal) {
    // Start from athlete's current level, increase based on goal
    double base = profile.weeklyDistance > 0 ? profile.weeklyDistance : 15;

    switch (goal) {
      case TrainingGoal.general5k:
        return base.clamp(15, 30);
      case TrainingGoal.general10k:
        return base.clamp(20, 40);
      case TrainingGoal.halfMarathon:
        return base.clamp(30, 55);
      case TrainingGoal.marathon:
        return base.clamp(40, 80);
      case TrainingGoal.speedImprovement:
        return base.clamp(20, 45);
      case TrainingGoal.enduranceBase:
        return base.clamp(25, 50);
      case TrainingGoal.maintenance:
        return base;
    }
  }

  List<WorkoutType?> _getWeeklySchedule(
      FitnessLevel level, TrainingGoal goal, bool isRecoveryWeek) {
    // Mon, Tue, Wed, Thu, Fri, Sat, Sun
    if (isRecoveryWeek) {
      return [
        WorkoutType.easyRun,
        null,
        WorkoutType.easyRun,
        null,
        WorkoutType.easyRun,
        null,
        null,
      ];
    }

    switch (level) {
      case FitnessLevel.beginner:
        return [
          WorkoutType.easyRun,
          null,
          WorkoutType.easyRun,
          null,
          null,
          WorkoutType.longRun,
          null,
        ];
      case FitnessLevel.intermediate:
        return [
          WorkoutType.easyRun,
          WorkoutType.tempo,
          null,
          WorkoutType.easyRun,
          null,
          WorkoutType.longRun,
          null,
        ];
      case FitnessLevel.advanced:
      case FitnessLevel.elite:
        return [
          WorkoutType.easyRun,
          WorkoutType.intervals,
          WorkoutType.easyRun,
          WorkoutType.tempo,
          null,
          WorkoutType.longRun,
          WorkoutType.recovery,
        ];
    }
  }

  String _getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[day];
  }

  String _getWeekTheme(int week, TrainingGoal goal, bool isRecoveryWeek) {
    if (isRecoveryWeek) return 'Recovery & Consolidation';

    switch (week) {
      case 1:
        return 'Foundation Building';
      case 2:
        return 'Progressive Overload';
      case 3:
        return 'Peak Training';
      default:
        return 'Training Week $week';
    }
  }

  StructuredWorkout _createWorkout(WorkoutType type, AthleteProfile profile,
      double weekDistance, TrainingGoal goal) {
    final pacePerKm =
        profile.avgPace > 0 ? profile.avgPace : 6.0; // Default 6 min/km

    switch (type) {
      case WorkoutType.easyRun:
        return _createEasyRun(pacePerKm, weekDistance);
      case WorkoutType.tempo:
        return _createTempoRun(pacePerKm, weekDistance);
      case WorkoutType.intervals:
        return _createIntervalWorkout(pacePerKm, goal);
      case WorkoutType.longRun:
        return _createLongRun(pacePerKm, weekDistance, goal);
      case WorkoutType.recovery:
        return _createRecoveryRun(pacePerKm);
      case WorkoutType.fartlek:
        return _createFartlek(pacePerKm);
      case WorkoutType.hills:
        return _createHillSession(pacePerKm);
    }
  }

  StructuredWorkout _createEasyRun(double basePace, double weekDistance) {
    final distance = (weekDistance * 0.15).clamp(3.0, 8.0) * 1000; // meters

    return StructuredWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Easy Run',
      description:
          'Comfortable aerobic pace. Should be able to hold a conversation.',
      steps: [
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_warmup',
          type: StepType.warmUp,
          target: StepTarget.duration,
          targetValue: 5 * 60, // 5 min
          order: 0,
        ),
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_run',
          type: StepType.run,
          target: StepTarget.distance,
          targetValue: distance,
          targetUnit: 'm',
          order: 1,
        ),
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_cooldown',
          type: StepType.coolDown,
          target: StepTarget.duration,
          targetValue: 5 * 60,
          order: 2,
        ),
      ],
    );
  }

  StructuredWorkout _createTempoRun(double basePace, double weekDistance) {
    final tempoDistance = (weekDistance * 0.12).clamp(3.0, 8.0) * 1000;

    return StructuredWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Tempo Run',
      description:
          'Comfortably hard pace. Challenging but sustainable for 20-40 minutes.',
      steps: [
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_warmup',
          type: StepType.warmUp,
          target: StepTarget.duration,
          targetValue: 10 * 60,
          order: 0,
        ),
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_tempo',
          type: StepType.run,
          target: StepTarget.distance,
          targetValue: tempoDistance,
          targetUnit: 'm',
          order: 1,
        ),
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_cooldown',
          type: StepType.coolDown,
          target: StepTarget.duration,
          targetValue: 10 * 60,
          order: 2,
        ),
      ],
    );
  }

  StructuredWorkout _createIntervalWorkout(double basePace, TrainingGoal goal) {
    int reps;
    double intervalDistance;

    switch (goal) {
      case TrainingGoal.general5k:
      case TrainingGoal.speedImprovement:
        reps = 6;
        intervalDistance = 400;
        break;
      case TrainingGoal.general10k:
        reps = 5;
        intervalDistance = 800;
        break;
      case TrainingGoal.halfMarathon:
      case TrainingGoal.marathon:
        reps = 4;
        intervalDistance = 1000;
        break;
      default:
        reps = 5;
        intervalDistance = 600;
    }

    final steps = <WorkoutStep>[
      WorkoutStep(
        id: '${DateTime.now().millisecondsSinceEpoch}_warmup',
        type: StepType.warmUp,
        target: StepTarget.duration,
        targetValue: 15 * 60,
        order: 0,
      ),
    ];

    // Add interval repeats
    for (int i = 0; i < reps; i++) {
      steps.add(WorkoutStep(
        id: '${DateTime.now().millisecondsSinceEpoch}_interval_$i',
        type: StepType.run,
        target: StepTarget.distance,
        targetValue: intervalDistance,
        targetUnit: 'm',
        order: steps.length,
      ));

      if (i < reps - 1) {
        steps.add(WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_recovery_$i',
          type: StepType.recovery,
          target: StepTarget.duration,
          targetValue: 90, // 90 sec jog
          order: steps.length,
        ));
      }
    }

    steps.add(WorkoutStep(
      id: '${DateTime.now().millisecondsSinceEpoch}_cooldown',
      type: StepType.coolDown,
      target: StepTarget.duration,
      targetValue: 10 * 60,
      order: steps.length,
    ));

    return StructuredWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Interval Training',
      description:
          '${reps}x${intervalDistance.toInt()}m at fast pace with recovery jogs.',
      steps: steps,
    );
  }

  StructuredWorkout _createLongRun(
      double basePace, double weekDistance, TrainingGoal goal) {
    double longRunDistance;
    switch (goal) {
      case TrainingGoal.general5k:
        longRunDistance = (weekDistance * 0.35).clamp(5.0, 10.0);
        break;
      case TrainingGoal.general10k:
        longRunDistance = (weekDistance * 0.35).clamp(8.0, 15.0);
        break;
      case TrainingGoal.halfMarathon:
        longRunDistance = (weekDistance * 0.35).clamp(12.0, 20.0);
        break;
      case TrainingGoal.marathon:
        longRunDistance = (weekDistance * 0.35).clamp(18.0, 32.0);
        break;
      default:
        longRunDistance = (weekDistance * 0.35).clamp(8.0, 15.0);
    }

    return StructuredWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Long Run',
      description:
          'Build endurance at comfortable pace. Focus on time on feet.',
      steps: [
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_warmup',
          type: StepType.warmUp,
          target: StepTarget.duration,
          targetValue: 5 * 60,
          order: 0,
        ),
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_longrun',
          type: StepType.run,
          target: StepTarget.distance,
          targetValue: longRunDistance * 1000,
          targetUnit: 'm',
          order: 1,
        ),
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_cooldown',
          type: StepType.coolDown,
          target: StepTarget.duration,
          targetValue: 5 * 60,
          order: 2,
        ),
      ],
    );
  }

  StructuredWorkout _createRecoveryRun(double basePace) {
    return StructuredWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Recovery Run',
      description: 'Very easy jog to promote blood flow and recovery.',
      steps: [
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_recovery',
          type: StepType.run,
          target: StepTarget.duration,
          targetValue: 25 * 60, // 25 min          order: 0,
        ),
      ],
    );
  }

  StructuredWorkout _createFartlek(double basePace) {
    return StructuredWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Fartlek Run',
      description: 'Speed play - vary your pace throughout based on feel.',
      steps: [
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_warmup',
          type: StepType.warmUp,
          target: StepTarget.duration,
          targetValue: 10 * 60,
          order: 0,
        ),
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_fartlek',
          type: StepType.run,
          target: StepTarget.duration,
          targetValue: 20 * 60,
          notes: 'Alternate between fast and easy efforts based on feel',
          order: 1,
        ),
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_cooldown',
          type: StepType.coolDown,
          target: StepTarget.duration,
          targetValue: 10 * 60,
          order: 2,
        ),
      ],
    );
  }

  StructuredWorkout _createHillSession(double basePace) {
    return StructuredWorkout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Hill Repeats',
      description: 'Build strength and power with hill training.',
      steps: [
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_warmup',
          type: StepType.warmUp,
          target: StepTarget.duration,
          targetValue: 15 * 60,
          order: 0,
        ),
        // 6 hill repeats
        for (int i = 0; i < 6; i++) ...[
          WorkoutStep(
            id: '${DateTime.now().millisecondsSinceEpoch}_hill_$i',
            type: StepType.run,
            target: StepTarget.duration,
            targetValue: 60, // 60 sec uphill
            notes: 'Hard effort uphill',
            order: 1 + (i * 2),
          ),
          WorkoutStep(
            id: '${DateTime.now().millisecondsSinceEpoch}_jog_$i',
            type: StepType.recovery,
            target: StepTarget.duration,
            targetValue: 90, // Jog down
            notes: 'Easy jog downhill',
            order: 2 + (i * 2),
          ),
        ],
        WorkoutStep(
          id: '${DateTime.now().millisecondsSinceEpoch}_cooldown',
          type: StepType.coolDown,
          target: StepTarget.duration,
          targetValue: 10 * 60,
          order: 14,
        ),
      ],
    );
  }

  /// Save training plan to database
  Future<void> savePlan(TrainingPlan plan) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Save each workout to athlete_calendar
    for (final week in plan.weeks) {
      for (final day in week.days) {
        if (day.workout != null && !day.isRestDay) {
          await _supabase.from('athlete_calendar').insert({
            'athlete_id': userId,
            'scheduled_date': day.date.toIso8601String(),
            'title': day.workout!.name,
            'description': day.workout!.description,
            'workout_type':
                day.workout!.name.toLowerCase().replaceAll(' ', '_'),
            'planned_duration': _calculateWorkoutDuration(day.workout!),
            'planned_distance': _calculateWorkoutDistance(day.workout!),
            'notes': 'Generated by AI Training Plan: ${plan.name}',
            'status': 'scheduled',
          });
        }
      }
    }
  }

  int _calculateWorkoutDuration(StructuredWorkout workout) {
    int total = 0;
    for (final step in workout.steps) {
      if (step.target == StepTarget.duration) {
        total += (step.targetValue ?? 0).toInt();
      } else {
        // Estimate duration from distance (assume ~6 min/km)
        total += ((step.targetValue ?? 0) / 1000 * 6 * 60).toInt();
      }
    }
    return (total / 60).round(); // Return minutes
  }

  double _calculateWorkoutDistance(StructuredWorkout workout) {
    double total = 0;
    for (final step in workout.steps) {
      if (step.target == StepTarget.distance) {
        total += (step.targetValue ?? 0);
      }
    }
    return total / 1000; // Return km
  }
}

// Data Models
enum FitnessLevel { beginner, intermediate, advanced, elite }

enum TrainingGoal {
  general5k,
  general10k,
  halfMarathon,
  marathon,
  speedImprovement,
  enduranceBase,
  maintenance
}

enum WorkoutType {
  easyRun,
  tempo,
  intervals,
  longRun,
  recovery,
  fartlek,
  hills
}

class AthleteProfile {
  final FitnessLevel level;
  final double weeklyDistance; // km
  final double avgPace; // min/km
  final double weeklyRuns;
  final double longestRun; // km
  final double avgHeartRate;

  AthleteProfile({
    required this.level,
    required this.weeklyDistance,
    required this.avgPace,
    required this.weeklyRuns,
    required this.longestRun,
    required this.avgHeartRate,
  });

  String get levelDescription {
    switch (level) {
      case FitnessLevel.beginner:
        return 'Beginner (<15km/week)';
      case FitnessLevel.intermediate:
        return 'Intermediate (15-30km/week)';
      case FitnessLevel.advanced:
        return 'Advanced (30-50km/week)';
      case FitnessLevel.elite:
        return 'Elite (50+km/week)';
    }
  }
}

class TrainingPlan {
  final String name;
  final TrainingGoal goal;
  final DateTime startDate;
  final List<TrainingWeek> weeks;
  final AthleteProfile athleteProfile;

  TrainingPlan({
    required this.name,
    required this.goal,
    required this.startDate,
    required this.weeks,
    required this.athleteProfile,
  });

  double get totalDistance =>
      weeks.fold(0.0, (sum, w) => sum + w.totalDistance);
  int get totalWorkouts =>
      weeks.fold(0, (sum, w) => sum + w.days.where((d) => !d.isRestDay).length);
}

class TrainingWeek {
  final int weekNumber;
  final String theme;
  final double totalDistance;
  final List<TrainingDay> days;

  TrainingWeek({
    required this.weekNumber,
    required this.theme,
    required this.totalDistance,
    required this.days,
  });
}

class TrainingDay {
  final DateTime date;
  final String dayOfWeek;
  final StructuredWorkout? workout;
  final bool isRestDay;

  TrainingDay({
    required this.date,
    required this.dayOfWeek,
    this.workout,
    this.isRestDay = false,
  });
}
