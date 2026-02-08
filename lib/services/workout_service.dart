// Workout Service
// Handles CRUD operations for structured workouts
// Supports local storage and Supabase sync

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_step.dart';
import 'dart:developer' as developer;

class WorkoutService {
  static const String _workoutsKey = 'structured_workouts';
  static const String _templatesKey = 'workout_templates';

  final SupabaseClient? _supabase;

  WorkoutService() : _supabase = _getSupabaseClient();

  static SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (e) {
      developer.log('⚠️ Supabase not initialized, using local storage only');
      return null;
    }
  }

  // Save workout (local + cloud)
  Future<void> saveWorkout(StructuredWorkout workout) async {
    // Save locally first
    await _saveLocally(workout);

    // Then sync to cloud if available
    if (_supabase != null) {
      try {
        await _syncToCloud(workout);
      } catch (e) {
        developer.log('⚠️ Failed to sync to cloud: $e');
        // Continue anyway - local save succeeded
      }
    }
  }

  // Get all workouts
  Future<List<StructuredWorkout>> getAllWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_workoutsKey);

    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => StructuredWorkout.fromJson(item)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      developer.log('⚠️ Error loading workouts: $e');
      return [];
    }
  }

  // Get workout by ID
  Future<StructuredWorkout?> getWorkout(String id) async {
    final workouts = await getAllWorkouts();
    try {
      return workouts.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get workouts for a specific date
  Future<List<StructuredWorkout>> getWorkoutsForDate(DateTime date) async {
    final workouts = await getAllWorkouts();
    return workouts.where((w) {
      if (w.scheduledDate == null) return false;
      return w.scheduledDate!.year == date.year &&
          w.scheduledDate!.month == date.month &&
          w.scheduledDate!.day == date.day;
    }).toList();
  }

  // Get upcoming workouts
  Future<List<StructuredWorkout>> getUpcomingWorkouts({int limit = 7}) async {
    final workouts = await getAllWorkouts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return workouts
        .where(
            (w) => w.scheduledDate != null && !w.scheduledDate!.isBefore(today))
        .toList()
      ..sort((a, b) => a.scheduledDate!.compareTo(b.scheduledDate!))
      ..take(limit);
  }

  // Delete workout
  Future<void> deleteWorkout(String id) async {
    final workouts = await getAllWorkouts();
    workouts.removeWhere((w) => w.id == id);
    await _saveAll(workouts);

    if (_supabase != null) {
      try {
        await _supabase.from('structured_workouts').delete().eq('id', id);
      } catch (e) {
        developer.log('⚠️ Failed to delete from cloud: $e');
      }
    }
  }

  // Get workout templates
  Future<List<StructuredWorkout>> getTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_templatesKey);

    if (json == null) return _getDefaultTemplates();

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((item) => StructuredWorkout.fromJson(item)).toList();
    } catch (e) {
      return _getDefaultTemplates();
    }
  }

  // Save as template
  Future<void> saveAsTemplate(StructuredWorkout workout) async {
    final templates = await getTemplates();
    final template = workout.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isTemplate: true,
      scheduledDate: null,
    );
    templates.add(template);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _templatesKey, jsonEncode(templates.map((t) => t.toJson()).toList()));
  }

  // Create workout from template
  Future<StructuredWorkout> createFromTemplate(StructuredWorkout template,
      {DateTime? scheduledDate}) async {
    return template.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isTemplate: false,
      scheduledDate: scheduledDate,
      createdAt: DateTime.now(),
    );
  }

  // Duplicate workout
  Future<StructuredWorkout> duplicateWorkout(StructuredWorkout workout,
      {DateTime? newDate}) async {
    final duplicate = workout.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${workout.name} (Copy)',
      scheduledDate: newDate ?? workout.scheduledDate,
      createdAt: DateTime.now(),
    );
    await saveWorkout(duplicate);
    return duplicate;
  }

  // Schedule workout for a date
  Future<void> scheduleWorkout(String workoutId, DateTime date) async {
    final workout = await getWorkout(workoutId);
    if (workout != null) {
      final updated = workout.copyWith(scheduledDate: date);
      await saveWorkout(updated);
    }
  }

  // Unschedule workout
  Future<void> unscheduleWorkout(String workoutId) async {
    final workout = await getWorkout(workoutId);
    if (workout != null) {
      final updated = StructuredWorkout(
        id: workout.id,
        name: workout.name,
        description: workout.description,
        activityType: workout.activityType,
        steps: workout.steps,
        createdAt: workout.createdAt,
        scheduledDate: null,
        notes: workout.notes,
        isTemplate: workout.isTemplate,
        athleteId: workout.athleteId,
      );
      await saveWorkout(updated);
    }
  }

  // Private: Save single workout locally
  Future<void> _saveLocally(StructuredWorkout workout) async {
    final workouts = await getAllWorkouts();

    // Update existing or add new
    final index = workouts.indexWhere((w) => w.id == workout.id);
    if (index >= 0) {
      workouts[index] = workout;
    } else {
      workouts.add(workout);
    }

    await _saveAll(workouts);
  }

  // Private: Save all workouts
  Future<void> _saveAll(List<StructuredWorkout> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _workoutsKey, jsonEncode(workouts.map((w) => w.toJson()).toList()));
  }

  // Private: Sync to cloud
  Future<void> _syncToCloud(StructuredWorkout workout) async {
    if (_supabase == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = workout.toJson();
    data['user_id'] = userId;

    await _supabase.from('structured_workouts').upsert(data);
  }

  // Private: Get default templates
  List<StructuredWorkout> _getDefaultTemplates() {
    return [
      // Easy Run
      StructuredWorkout(
        name: 'Easy Run',
        description: 'Recovery or easy aerobic run',
        isTemplate: true,
        steps: [
          WorkoutStep(
              type: StepType.warmUp,
              target: StepTarget.duration,
              targetValue: 300,
              order: 0),
          WorkoutStep(
              type: StepType.run,
              target: StepTarget.distance,
              targetValue: 5000,
              targetUnit: 'km',
              order: 1),
          WorkoutStep(
              type: StepType.coolDown,
              target: StepTarget.duration,
              targetValue: 300,
              order: 2),
        ],
      ),

      // 5K Race Pace
      StructuredWorkout(
        name: '5K Race Pace',
        description: 'Build race-specific fitness',
        isTemplate: true,
        steps: [
          WorkoutStep(
              type: StepType.warmUp,
              target: StepTarget.duration,
              targetValue: 600,
              order: 0),
          WorkoutStep(
              type: StepType.repeat,
              repeatCount: 5,
              repeatSteps: [
                WorkoutStep(
                    type: StepType.interval,
                    target: StepTarget.distance,
                    targetValue: 1000,
                    targetUnit: 'm',
                    order: 0),
                WorkoutStep(
                    type: StepType.recovery,
                    target: StepTarget.duration,
                    targetValue: 120,
                    order: 1),
              ],
              order: 1),
          WorkoutStep(
              type: StepType.coolDown,
              target: StepTarget.duration,
              targetValue: 600,
              order: 2),
        ],
      ),

      // Tempo Run
      StructuredWorkout(
        name: 'Tempo Run',
        description: 'Sustained effort at threshold pace',
        isTemplate: true,
        steps: [
          WorkoutStep(
              type: StepType.warmUp,
              target: StepTarget.duration,
              targetValue: 600,
              order: 0),
          WorkoutStep(
              type: StepType.run,
              target: StepTarget.duration,
              targetValue: 1200,
              targetHRZone: 4,
              order: 1),
          WorkoutStep(
              type: StepType.coolDown,
              target: StepTarget.duration,
              targetValue: 600,
              order: 2),
        ],
      ),

      // Long Run
      StructuredWorkout(
        name: 'Long Run',
        description: 'Build aerobic endurance',
        isTemplate: true,
        steps: [
          WorkoutStep(type: StepType.warmUp, target: StepTarget.open, order: 0),
          WorkoutStep(
              type: StepType.run,
              target: StepTarget.distance,
              targetValue: 16000,
              targetUnit: 'km',
              targetHRZone: 2,
              order: 1),
          WorkoutStep(
              type: StepType.coolDown, target: StepTarget.open, order: 2),
        ],
      ),

      // Speed Work
      StructuredWorkout(
        name: 'Speed Work - 400m Repeats',
        description: 'Improve speed and running economy',
        isTemplate: true,
        steps: [
          WorkoutStep(
              type: StepType.warmUp,
              target: StepTarget.duration,
              targetValue: 600,
              order: 0),
          WorkoutStep(
              type: StepType.repeat,
              repeatCount: 8,
              repeatSteps: [
                WorkoutStep(
                    type: StepType.interval,
                    target: StepTarget.distance,
                    targetValue: 400,
                    targetUnit: 'm',
                    order: 0),
                WorkoutStep(
                    type: StepType.recovery,
                    target: StepTarget.duration,
                    targetValue: 90,
                    order: 1),
              ],
              order: 1),
          WorkoutStep(
              type: StepType.coolDown,
              target: StepTarget.duration,
              targetValue: 600,
              order: 2),
        ],
      ),

      // Fartlek
      StructuredWorkout(
        name: 'Fartlek',
        description: 'Varied pace training',
        isTemplate: true,
        steps: [
          WorkoutStep(
              type: StepType.warmUp,
              target: StepTarget.duration,
              targetValue: 600,
              order: 0),
          WorkoutStep(
              type: StepType.repeat,
              repeatCount: 4,
              repeatSteps: [
                WorkoutStep(
                    type: StepType.interval,
                    target: StepTarget.duration,
                    targetValue: 180,
                    order: 0),
                WorkoutStep(
                    type: StepType.recovery,
                    target: StepTarget.duration,
                    targetValue: 120,
                    order: 1),
                WorkoutStep(
                    type: StepType.interval,
                    target: StepTarget.duration,
                    targetValue: 90,
                    order: 2),
                WorkoutStep(
                    type: StepType.recovery,
                    target: StepTarget.duration,
                    targetValue: 60,
                    order: 3),
              ],
              order: 1),
          WorkoutStep(
              type: StepType.coolDown,
              target: StepTarget.duration,
              targetValue: 600,
              order: 2),
        ],
      ),
    ];
  }

  // Sync all workouts from cloud
  Future<void> syncFromCloud() async {
    if (_supabase == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('structured_workouts')
          .select()
          .eq('user_id', userId);

      final cloudWorkouts = (response as List)
          .map((item) => StructuredWorkout.fromJson(item))
          .toList();

      // Merge with local
      final localWorkouts = await getAllWorkouts();
      final merged = <String, StructuredWorkout>{};

      for (final w in localWorkouts) {
        merged[w.id] = w;
      }
      for (final w in cloudWorkouts) {
        // Cloud version takes precedence if newer
        if (!merged.containsKey(w.id) ||
            w.createdAt.isAfter(merged[w.id]!.createdAt)) {
          merged[w.id] = w;
        }
      }

      await _saveAll(merged.values.toList());
    } catch (e) {
      developer.log('⚠️ Failed to sync from cloud: $e');
    }
  }
}
