// Progression Plan Database Service
// Saves and retrieves adaptive pace progression plans

import 'package:supabase_flutter/supabase_flutter.dart';
import 'adaptive_pace_progression.dart';
import 'dart:convert';

class ProgressionPlanService {
  static final supabase = Supabase.instance.client;

  /// Save progression plan to database
  static Future<void> savePlan({
    required String athleteId,
    required ProgressionPlan plan,
  }) async {
    try {
      // Convert plan to JSON
      final planData = {
        'athlete_id': athleteId,
        'total_weeks': plan.totalWeeks,
        'start_pace': plan.startPace,
        'goal_pace': plan.goalPace,
        'start_mileage': plan.startMileage,
        'goal_mileage': plan.goalMileage,
        'start_aisri': plan.startAISRI,
        'goal_aisri': plan.goalAISRI,
        'current_week': 1,
        'phases': plan.phases.map((p) => p.toString().split('.').last).toList(),
        'weekly_plans':
            plan.weeklyPlans.map((w) => _weeklyPlanToJson(w)).toList(),
        'summary': plan.summary,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Upsert to progression_plans table
      await supabase.from('progression_plans').upsert(planData);

      print('✅ Progression plan saved successfully');
    } catch (e) {
      print('❌ Error saving progression plan: $e');
      throw Exception('Failed to save progression plan');
    }
  }

  /// Get active progression plan for athlete
  static Future<ProgressionPlan?> getActivePlan(String athleteId) async {
    try {
      final response = await supabase
          .from('progression_plans')
          .select()
          .eq('athlete_id', athleteId)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) {
        print('No active progression plan found');
        return null;
      }

      return _jsonToPlan(response);
    } catch (e) {
      print('❌ Error fetching progression plan: $e');
      return null;
    }
  }

  /// Update current week
  static Future<void> updateCurrentWeek({
    required String athleteId,
    required int weekNumber,
  }) async {
    try {
      await supabase
          .from('progression_plans')
          .update({'current_week': weekNumber})
          .eq('athlete_id', athleteId)
          .eq('status', 'active');

      print('✅ Updated current week to $weekNumber');
    } catch (e) {
      print('❌ Error updating current week: $e');
    }
  }

  /// Mark plan as completed
  static Future<void> completePlan(String athleteId) async {
    try {
      await supabase
          .from('progression_plans')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('athlete_id', athleteId)
          .eq('status', 'active');

      print('🎉 Progression plan marked as completed!');
    } catch (e) {
      print('❌ Error completing plan: $e');
    }
  }

  /// Get progression statistics
  static Future<Map<String, dynamic>> getProgressStats(String athleteId) async {
    try {
      final plan = await getActivePlan(athleteId);
      if (plan == null) {
        return {
          'has_plan': false,
        };
      }

      // Get current week from database
      final response = await supabase
          .from('progression_plans')
          .select('current_week')
          .eq('athlete_id', athleteId)
          .eq('status', 'active')
          .maybeSingle();

      final currentWeek = response?['current_week'] ?? 1;
      final currentPlan = plan.weeklyPlans[currentWeek - 1];
      final progressPercent = (currentWeek / plan.totalWeeks * 100).round();

      // Calculate pace improvement so far
      final currentTargetPace = currentPlan.targetPace;
      final paceImproved = plan.startPace - currentTargetPace;
      final totalPaceGoal = plan.startPace - plan.goalPace;
      final paceProgress = (paceImproved / totalPaceGoal * 100).round();

      return {
        'has_plan': true,
        'current_week': currentWeek,
        'total_weeks': plan.totalWeeks,
        'progress_percent': progressPercent,
        'start_pace': plan.startPace,
        'current_target_pace': currentTargetPace,
        'goal_pace': plan.goalPace,
        'pace_improved': paceImproved,
        'pace_progress': paceProgress,
        'current_phase': currentPlan.phase.toString().split('.').last,
        'weeks_remaining': plan.totalWeeks - currentWeek,
      };
    } catch (e) {
      print('❌ Error getting progress stats: $e');
      return {'has_plan': false};
    }
  }

  /// Convert WeeklyPlan to JSON
  static Map<String, dynamic> _weeklyPlanToJson(WeeklyPlan plan) {
    return {
      'week_number': plan.weekNumber,
      'phase': plan.phase.toString().split('.').last,
      'target_pace': plan.targetPace,
      'tempo_target': plan.tempoWorktarget,
      'weekly_mileage': plan.weeklyMileage,
      'target_aisri': plan.targetAISRI,
      'focus': plan.focus,
      'notes': plan.notes,
      'workouts': plan.workouts.map((w) => _workoutToJson(w)).toList(),
    };
  }

  /// Convert DailyWorkout to JSON
  static Map<String, dynamic> _workoutToJson(DailyWorkout workout) {
    return {
      'day_number': workout.dayNumber,
      'type': workout.type,
      'name': workout.name,
      'description': workout.description,
      'distance': workout.distance,
      'duration': workout.duration,
      'zone': workout.zone?.toString().split('.').last,
      'target_pace': workout.targetPace,
      'target_hr': workout.targetHR,
      'intervals': workout.intervals
          ?.map((i) => {
                'duration': i.duration,
                'zone': i.zone.toString().split('.').last,
                'description': i.description,
                'pace': i.pace,
              })
          .toList(),
    };
  }

  /// Convert JSON to ProgressionPlan
  static ProgressionPlan _jsonToPlan(Map<String, dynamic> json) {
    final weeklyPlans = (json['weekly_plans'] as List)
        .map((w) => _jsonToWeeklyPlan(w))
        .toList();

    final phases =
        (json['phases'] as List).map((p) => _stringToPhase(p)).toList();

    return ProgressionPlan(
      totalWeeks: json['total_weeks'],
      startPace: json['start_pace'].toDouble(),
      goalPace: json['goal_pace'].toDouble(),
      startMileage: json['start_mileage'].toDouble(),
      goalMileage: json['goal_mileage'].toDouble(),
      startAISRI: json['start_aisri'],
      goalAISRI: json['goal_aisri'],
      phases: phases,
      weeklyPlans: weeklyPlans,
      summary: json['summary'],
    );
  }

  /// Convert JSON to WeeklyPlan
  static WeeklyPlan _jsonToWeeklyPlan(Map<String, dynamic> json) {
    final workouts =
        (json['workouts'] as List).map((w) => _jsonToWorkout(w)).toList();

    return WeeklyPlan(
      weekNumber: json['week_number'],
      phase: _stringToPhase(json['phase']),
      targetPace: json['target_pace'].toDouble(),
      tempoWorktarget: json['tempo_target'].toDouble(),
      weeklyMileage: json['weekly_mileage'].toDouble(),
      targetAISRI: json['target_aisri'],
      workouts: workouts,
      focus: List<String>.from(json['focus']),
      notes: json['notes'],
    );
  }

  /// Convert JSON to DailyWorkout
  static DailyWorkout _jsonToWorkout(Map<String, dynamic> json) {
    List<Interval>? intervals;
    if (json['intervals'] != null) {
      intervals = (json['intervals'] as List)
          .map((i) => Interval(
                duration: i['duration'],
                zone: _stringToZone(i['zone']),
                description: i['description'],
                pace: i['pace'],
              ))
          .toList();
    }

    return DailyWorkout(
      dayNumber: json['day_number'],
      type: json['type'],
      name: json['name'],
      description: json['description'],
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
      zone: json['zone'] != null ? _stringToZone(json['zone']) : null,
      intervals: intervals,
      targetPace: json['target_pace'],
      targetHR: json['target_hr'],
    );
  }

  /// Convert string to TrainingPhase enum
  static TrainingPhase _stringToPhase(String phase) {
    switch (phase) {
      case 'foundation':
        return TrainingPhase.foundation;
      case 'baseBuilding':
        return TrainingPhase.baseBuilding;
      case 'speedDevelopment':
        return TrainingPhase.speedDevelopment;
      case 'thresholdWork':
        return TrainingPhase.thresholdWork;
      case 'powerWork':
        return TrainingPhase.powerWork;
      case 'goalAchievement':
        return TrainingPhase.goalAchievement;
      default:
        return TrainingPhase.foundation;
    }
  }

  /// Convert string to HRZone enum
  static HRZone _stringToZone(String zone) {
    switch (zone) {
      case 'recovery':
        return HRZone.recovery;
      case 'foundation':
        return HRZone.foundation;
      case 'endurance':
        return HRZone.endurance;
      case 'threshold':
        return HRZone.threshold;
      case 'power':
        return HRZone.power;
      default:
        return HRZone.foundation;
    }
  }
}
