import 'package:supabase_flutter/supabase_flutter.dart';
import 'protocol_generator.dart';
import 'dart:developer' as developer;

class CalendarScheduler {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Schedule a generated protocol to the athlete's calendar
  Future<SchedulingResult> scheduleProtocol({
    required String athleteId,
    required GeneratedProtocol protocol,
    DateTime? startDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now();
      final scheduledWorkouts = <String>[];
      int successCount = 0;
      int failCount = 0;

      // First, create the protocol record
      final protocolId = await _createProtocolRecord(athleteId, protocol);

      // For each workout in the protocol
      for (var workout in protocol.workouts) {
        try {
          // Calculate the scheduled date
          final daysFromStart = ((workout.week - 1) * 7) +
              ((workout.dayOfWeek - 1) * 2); // Every other day
          final scheduledDate = start.add(Duration(days: daysFromStart));

          // Create workout record
          final workoutId = await _createWorkoutRecord(
            protocolId: protocolId,
            workout: workout,
          );

          // Schedule to calendar
          await _scheduleToCalendar(
            athleteId: athleteId,
            workoutId: workoutId,
            scheduledDate: scheduledDate,
          );

          scheduledWorkouts.add(workoutId);
          successCount++;
        } catch (e) {
          developer.log('Error scheduling workout: $e');
          failCount++;
        }
      }

      return SchedulingResult(
        success: successCount > 0,
        scheduledCount: successCount,
        failedCount: failCount,
        protocolId: protocolId,
        workoutIds: scheduledWorkouts,
        startDate: start,
        endDate: start.add(Duration(days: protocol.durationWeeks * 7)),
      );
    } catch (e) {
      developer.log('Error scheduling protocol: $e');
      return SchedulingResult(
        success: false,
        scheduledCount: 0,
        failedCount: protocol.workouts.length,
        protocolId: '',
        workoutIds: [],
        startDate: startDate ?? DateTime.now(),
        endDate: startDate ?? DateTime.now(),
      );
    }
  }

  // Create protocol record in database
  Future<String> _createProtocolRecord(
      String athleteId, GeneratedProtocol protocol) async {
    // First, get or create a coach profile for system-generated protocols
    final coachId = await _getSystemCoachId();

    final response = await _supabase
        .from('protocols')
        .insert({
          'coach_id': coachId,
          'protocol_name': protocol.protocolName,
          'protocol_type': _determineProtocolType(protocol.focusAreas),
          'description': protocol.description,
          'duration_weeks': protocol.durationWeeks,
          'frequency_per_week': protocol.workoutsPerWeek,
          'target_injury':
              protocol.injuryRisk == 'high' ? 'High injury risk' : null,
          'target_deficit': protocol.focusAreas.join(', '),
          'expected_outcomes':
              'Improved ${protocol.focusAreas.join(", ")} performance',
          'is_template': false,
        })
        .select('id')
        .single();

    final protocolId = response['id'] as String;

    // Create athlete_protocol link
    await _supabase.from('athlete_protocols').insert({
      'athlete_id': athleteId,
      'protocol_id': protocolId,
      'assigned_by': coachId,
      'status': 'active',
      'started_at': DateTime.now().toIso8601String(),
      'total_workouts_scheduled': protocol.totalWorkouts,
    });

    return protocolId;
  }

  // Get or create system coach for auto-generated protocols
  Future<String> _getSystemCoachId() async {
    try {
      // Try to get existing system coach
      final response = await _supabase
          .from('coach_profiles')
          .select('id')
          .eq('coach_name', 'Coach Kura (AI)')
          .maybeSingle();

      if (response != null) {
        return response['id'] as String;
      }

      // Create system coach if it doesn't exist
      // Note: This requires a valid user_id from auth.users
      // For now, we'll use the current user's ID and create a coach profile
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No user logged in');

      final newCoach = await _supabase
          .from('coach_profiles')
          .insert({
            'user_id': userId,
            'coach_name': 'Coach Kura (AI)',
            'specialization': 'AI-Powered Running Coach',
            'bio':
                'Automated protocol generation based on Strava data and AISRI assessment',
          })
          .select('id')
          .single();

      return newCoach['id'] as String;
    } catch (e) {
      developer.log('Error getting system coach: $e');
      // Fallback: use current user as coach
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('No user logged in');

      // Create a minimal coach profile
      final newCoach = await _supabase
          .from('coach_profiles')
          .insert({
            'user_id': userId,
            'coach_name': 'Self-Assigned',
            'specialization': 'Self-Training',
          })
          .select('id')
          .single();

      return newCoach['id'] as String;
    }
  }

  // Create workout record
  Future<String> _createWorkoutRecord({
    required String protocolId,
    required GeneratedWorkout workout,
  }) async {
    // Get athlete_protocol_id
    final athleteProtocol = await _supabase
        .from('athlete_protocols')
        .select('id')
        .eq('protocol_id', protocolId)
        .single();

    final athleteProtocolId = athleteProtocol['id'] as String;

    // Build exercises JSON
    final exercisesJson = workout.exercises.map((ex) {
      return {
        'name': ex['exercise_name'],
        'sets': ex['default_sets'],
        'reps': ex['default_reps'],
        'duration_seconds': ex['default_duration_seconds'],
        'rest_seconds': ex['default_rest_seconds'],
        'notes': ex['description'],
      };
    }).toList();

    final response = await _supabase
        .from('workouts')
        .insert({
          'athlete_protocol_id': athleteProtocolId,
          'workout_name': workout.workoutName,
          'workout_type': workout.workoutType,
          'exercises': exercisesJson,
          'estimated_duration_minutes': workout.estimatedDuration,
          'difficulty': workout.difficulty,
          'equipment_needed': workout.equipmentNeeded,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  // Schedule workout to calendar
  Future<void> _scheduleToCalendar({
    required String athleteId,
    required String workoutId,
    required DateTime scheduledDate,
  }) async {
    final dateStr =
        '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';

    await _supabase.from('athlete_calendar').insert({
      'athlete_id': athleteId,
      'workout_id': workoutId,
      'scheduled_date': dateStr,
      'scheduled_time': '09:00:00', // Default to 9 AM
      'status': 'pending',
    });
  }

  // Determine protocol type from focus areas
  String _determineProtocolType(List<String> focusAreas) {
    if (focusAreas.contains('injury_prevention')) return 'rehab';
    if (focusAreas.contains('strength')) return 'strength';
    if (focusAreas.contains('mobility')) return 'mobility';
    if (focusAreas.contains('cadence')) return 'performance';
    return 'prevention';
  }

  // Clear existing scheduled workouts (optional - use before rescheduling)
  Future<bool> clearExistingSchedule(String athleteId) async {
    try {
      await _supabase
          .from('athlete_calendar')
          .delete()
          .eq('athlete_id', athleteId)
          .eq('status', 'pending');
      return true;
    } catch (e) {
      developer.log('Error clearing schedule: $e');
      return false;
    }
  }
}

class SchedulingResult {
  final bool success;
  final int scheduledCount;
  final int failedCount;
  final String protocolId;
  final List<String> workoutIds;
  final DateTime startDate;
  final DateTime endDate;

  SchedulingResult({
    required this.success,
    required this.scheduledCount,
    required this.failedCount,
    required this.protocolId,
    required this.workoutIds,
    required this.startDate,
    required this.endDate,
  });

  String get summary {
    if (!success) return 'Failed to schedule workouts';
    return 'Scheduled $scheduledCount workouts from ${_formatDate(startDate)} to ${_formatDate(endDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
