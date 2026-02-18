import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/structured_workout.dart';

class StructuredWorkoutService {
  final _supabase = Supabase.instance.client;

  // Create a new structured workout
  Future<void> createWorkout(StructuredWorkout workout) async {
    await _supabase.from('structured_workouts').insert({
      'id': workout.id,
      'coach_id': workout.coachId,
      'workout_name': workout.workoutName,
      'description': workout.description,
      'activity_type': workout.activityType,
      'steps': workout.steps.map((s) => s.toJson()).toList(),
      'estimated_duration': workout.estimatedDuration,
      'estimated_distance': workout.estimatedDistance,
      'created_at': workout.createdAt.toIso8601String(),
    });
  }

  // Update existing workout
  Future<void> updateWorkout(StructuredWorkout workout) async {
    await _supabase.from('structured_workouts').update({
      'workout_name': workout.workoutName,
      'description': workout.description,
      'activity_type': workout.activityType,
      'steps': workout.steps.map((s) => s.toJson()).toList(),
      'estimated_duration': workout.estimatedDuration,
      'estimated_distance': workout.estimatedDistance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', workout.id);
  }

  // Delete workout
  Future<void> deleteWorkout(String workoutId) async {
    await _supabase.from('structured_workouts').delete().eq('id', workoutId);
  }

  // Get all workouts for a coach
  Future<List<StructuredWorkout>> getCoachWorkouts(String coachId) async {
    final response = await _supabase
        .from('structured_workouts')
        .select()
        .eq('coach_id', coachId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => StructuredWorkout.fromJson(json))
        .toList();
  }

  // Get single workout by ID
  Future<StructuredWorkout?> getWorkout(String workoutId) async {
    final response = await _supabase
        .from('structured_workouts')
        .select()
        .eq('id', workoutId)
        .single();

    return StructuredWorkout.fromJson(response);
  }

  // Assign workout to athlete
  Future<void> assignWorkout({
    required String workoutId,
    required String athleteId,
    required String coachId,
    required DateTime scheduledDate,
    String? notes,
  }) async {
    await _supabase.from('workout_assignments').insert({
      'structured_workout_id': workoutId,
      'athlete_id': athleteId,
      'coach_id': coachId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'status': 'scheduled',
      'notes': notes,
    });
  }

  // Get athlete's assigned workouts for a date range
  Future<List<Map<String, dynamic>>> getAthleteAssignments({
    required String athleteId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _supabase
        .from('workout_assignments')
        .select('*, structured_workouts(*)')
        .eq('athlete_id', athleteId)
        .gte('scheduled_date', startDate.toIso8601String().split('T')[0])
        .lte('scheduled_date', endDate.toIso8601String().split('T')[0])
        .order('scheduled_date');

    return List<Map<String, dynamic>>.from(response as List);
  }

  // Mark workout as completed
  Future<void> completeWorkout({
    required String assignmentId,
    required String gpsActivityId,
  }) async {
    await _supabase.from('workout_assignments').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
      'gps_activity_id': gpsActivityId,
    }).eq('id', assignmentId);
  }
}
