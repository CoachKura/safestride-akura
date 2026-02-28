// Workout Completion Model
// Track completed workouts and link to training plans

import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutCompletion {
  final String id;
  final String userId;
  final String? runSessionId; // FK to run_sessions
  final DateTime completedAt;
  final String workoutName;
  final String? workoutType; // easy, tempo, interval, long
  final double plannedDistanceKm;
  final double actualDistanceKm;
  final int plannedDurationSec;
  final int actualDurationSec;
  final String? plannedPaceGuide;
  final double? actualPaceMinPerKm;
  final int? weekNumber; // Week of training plan
  final String? trainingPlanGoal; // 5K, 10K, HM, Marathon
  final bool isOnPlan; // true if from training plan, false if free run

  WorkoutCompletion({
    required this.id,
    required this.userId,
    this.runSessionId,
    required this.completedAt,
    required this.workoutName,
    this.workoutType,
    required this.plannedDistanceKm,
    required this.actualDistanceKm,
    required this.plannedDurationSec,
    required this.actualDurationSec,
    this.plannedPaceGuide,
    this.actualPaceMinPerKm,
    this.weekNumber,
    this.trainingPlanGoal,
    required this.isOnPlan,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'run_session_id': runSessionId,
      'completed_at': completedAt.toIso8601String(),
      'workout_name': workoutName,
      'workout_type': workoutType,
      'planned_distance_km': plannedDistanceKm,
      'actual_distance_km': actualDistanceKm,
      'planned_duration_sec': plannedDurationSec,
      'actual_duration_sec': actualDurationSec,
      'planned_pace_guide': plannedPaceGuide,
      'actual_pace_min_per_km': actualPaceMinPerKm,
      'week_number': weekNumber,
      'training_plan_goal': trainingPlanGoal,
      'is_on_plan': isOnPlan,
    };
  }

  factory WorkoutCompletion.fromJson(Map<String, dynamic> json) {
    return WorkoutCompletion(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      runSessionId: json['run_session_id'] as String?,
      completedAt: DateTime.parse(json['completed_at'] as String),
      workoutName: json['workout_name'] as String,
      workoutType: json['workout_type'] as String?,
      plannedDistanceKm: (json['planned_distance_km'] as num).toDouble(),
      actualDistanceKm: (json['actual_distance_km'] as num).toDouble(),
      plannedDurationSec: json['planned_duration_sec'] as int,
      actualDurationSec: json['actual_duration_sec'] as int,
      plannedPaceGuide: json['planned_pace_guide'] as String?,
      actualPaceMinPerKm: json['actual_pace_min_per_km'] != null
          ? (json['actual_pace_min_per_km'] as num).toDouble()
          : null,
      weekNumber: json['week_number'] as int?,
      trainingPlanGoal: json['training_plan_goal'] as String?,
      isOnPlan: json['is_on_plan'] as bool,
    );
  }

  // Calculate adherence score (0-100)
  int get adherenceScore {
    // Distance match score (40 points)
    final distanceRatio = actualDistanceKm / plannedDistanceKm;
    final distanceScore = distanceRatio >= 0.9 && distanceRatio <= 1.1
        ? 40
        : distanceRatio >= 0.8 && distanceRatio <= 1.2
            ? 30
            : 20;

    // Duration match score (30 points)
    final durationRatio = actualDurationSec / plannedDurationSec;
    final durationScore = durationRatio >= 0.9 && durationRatio <= 1.1
        ? 30
        : durationRatio >= 0.8 && durationRatio <= 1.2
            ? 20
            : 10;

    // Completion score (30 points)
    final completionScore = 30;

    return distanceScore + durationScore + completionScore;
  }

  String get adherenceLabel {
    final score = adherenceScore;
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Improvement';
  }
}

class WorkoutCompletionService {
  static final _supabase = Supabase.instance.client;

  // Create workout completion record
  static Future<bool> recordCompletion(WorkoutCompletion completion) async {
    try {
      await _supabase.from('workout_completions').upsert(completion.toJson());
      return true;
    } catch (e) {
      print('Error recording workout completion: $e');
      return false;
    }
  }

  // Get user's workout completions
  static Future<List<WorkoutCompletion>> getUserCompletions({
    required String userId,
    int? weekNumber,
    String? trainingPlanGoal,
    int limit = 100,
  }) async {
    try {
      final query = _supabase
          .from('workout_completions')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(limit);

      final response = await query;

      return (response as List)
          .map((json) => WorkoutCompletion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading workout completions: $e');
      return [];
    }
  }

  // Calculate plan adherence percentage
  static Future<double> getPlanAdherence({
    required String userId,
    String? trainingPlanGoal,
    int? weekNumber,
  }) async {
    try {
      var completions = await getUserCompletions(
        userId: userId,
        trainingPlanGoal: trainingPlanGoal,
        weekNumber: weekNumber,
      );

      if (completions.isEmpty) return 0.0;

      final totalScore = completions.fold<int>(
        0,
        (sum, c) => sum + c.adherenceScore,
      );

      return (totalScore / (completions.length * 100)) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  // Get completed workout IDs for a training plan
  static Future<Set<String>> getCompletedWorkoutIds({
    required String userId,
    String? trainingPlanGoal,
  }) async {
    try {
      final completions = await getUserCompletions(
        userId: userId,
        trainingPlanGoal: trainingPlanGoal,
      );

      return completions
          .where((c) => c.isOnPlan)
          .map((c) => '${c.weekNumber}_${c.workoutName}')
          .toSet();
    } catch (e) {
      return {};
    }
  }

  // Get weekly summary
  static Future<WeeklySummary> getWeeklySummary({
    required String userId,
    int? weekNumber,
    String? trainingPlanGoal,
  }) async {
    try {
      final completions = await getUserCompletions(
        userId: userId,
        weekNumber: weekNumber,
        trainingPlanGoal: trainingPlanGoal,
      );

      final totalWorkouts = completions.length;
      final totalDistance = completions.fold<double>(
        0.0,
        (sum, c) => sum + c.actualDistanceKm,
      );
      final totalDuration = completions.fold<int>(
        0,
        (sum, c) => sum + c.actualDurationSec,
      );
      final avgAdherence = totalWorkouts > 0
          ? completions.fold<int>(0, (sum, c) => sum + c.adherenceScore) /
              totalWorkouts
          : 0.0;

      return WeeklySummary(
        workoutsCompleted: totalWorkouts,
        totalDistanceKm: totalDistance,
        totalDurationSec: totalDuration,
        avgAdherenceScore: avgAdherence,
      );
    } catch (e) {
      return WeeklySummary(
        workoutsCompleted: 0,
        totalDistanceKm: 0,
        totalDurationSec: 0,
        avgAdherenceScore: 0,
      );
    }
  }
}

class WeeklySummary {
  final int workoutsCompleted;
  final double totalDistanceKm;
  final int totalDurationSec;
  final double avgAdherenceScore;

  WeeklySummary({
    required this.workoutsCompleted,
    required this.totalDistanceKm,
    required this.totalDurationSec,
    required this.avgAdherenceScore,
  });
}
