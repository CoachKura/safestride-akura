import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_calendar_entry.dart';
import 'dart:developer' as developer;

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user's athlete profile ID
  Future<String?> _getAthleteId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('athlete_profiles')
          .select('id')
          .eq('user_id', userId)
          .single();

      return response['id'] as String;
    } catch (e) {
      developer.log('Error getting athlete ID: $e');
      return null;
    }
  }

  // Get workouts for a specific month (includes GPS activities from Strava)
  Future<List<WorkoutCalendarEntry>> getWorkoutsForMonth(DateTime month) async {
    try {
      final athleteId = await _getAthleteId();
      final userId = _supabase.auth.currentUser?.id;

      if (athleteId == null && userId == null) {
        // Return mock past workouts for testing
        return _getMockPastWorkouts(month);
      }

      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final List<WorkoutCalendarEntry> allWorkouts = [];

      // 1. Get planned workouts from athlete_calendar (if athleteId exists)
      if (athleteId != null) {
        try {
          final response = await _supabase
              .from('athlete_calendar')
              .select('''
                id,
                athlete_id,
                workout_id,
                scheduled_date,
                scheduled_time,
                status,
                completed_at,
                actual_duration_minutes,
                difficulty_rating,
                pain_level,
                reminder_sent,
                workouts (
                  id,
                  workout_name,
                  workout_type,
                  exercises,
                  estimated_duration_minutes,
                  difficulty,
                  equipment_needed
                )
              ''')
              .eq('athlete_id', athleteId)
              .gte('scheduled_date', firstDay.toIso8601String().split('T')[0])
              .lte('scheduled_date', lastDay.toIso8601String().split('T')[0])
              .order('scheduled_date', ascending: true);

          allWorkouts.addAll((response as List)
              .map((json) => WorkoutCalendarEntry.fromJson(json))
              .toList());
        } catch (e) {
          developer.log('Note: No planned workouts found: $e');
        }
      }

      // 2. Get actual GPS activities from gps_activities (Strava data)
      if (userId != null) {
        try {
          developer.log('🔍 Querying gps_activities for user: $userId');
          developer.log('📅 Date range: ${firstDay.toIso8601String()} to ${lastDay.toIso8601String()}');
          
          final response = await _supabase
              .from('gps_activities')
              .select()
              .eq('user_id', userId)
              .gte('start_time', firstDay.toIso8601String())
              .lte('start_time', lastDay.toIso8601String())
              .order('start_time', ascending: true);

          developer.log('✅ GPS activities found: ${(response as List).length}');
          
          // Convert GPS activities to WorkoutCalendarEntry
          for (var activity in response) {
            developer.log('  📍 Activity: ${activity['activity_type']} - ${activity['distance_meters']}m on ${activity['start_time']}');
            allWorkouts.add(WorkoutCalendarEntry.fromGpsActivity(activity));
          }
        } catch (e) {
          developer.log('❌ Error loading GPS activities: $e');
        }
      }

      return allWorkouts;
    } catch (e) {
      developer.log('Error fetching workouts for month: $e');
      return [];
    }
  }

  // Get today's workout
  Future<WorkoutCalendarEntry?> getTodayWorkout() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final athleteId = await _getAthleteId();

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // First, try to get completed GPS activity from today
      if (userId != null) {
        try {
          final gpsActivities = await _supabase
              .from('gps_activities')
              .select()
              .eq('user_id', userId)
              .gte('start_time', '${todayStr}T00:00:00')
              .lte('start_time', '${todayStr}T23:59:59')
              .order('start_time', ascending: false)
              .limit(1);

          if (gpsActivities.isNotEmpty) {
            return WorkoutCalendarEntry.fromGpsActivity(gpsActivities.first);
          }
        } catch (e) {
          developer.log('Note: No GPS activities for today: $e');
        }
      }

      // Then try planned workout from athlete_calendar
      if (athleteId != null) {
        try {
          final response = await _supabase
              .from('athlete_calendar')
              .select('''
                id,
                athlete_id,
                workout_id,
                scheduled_date,
                scheduled_time,
                status,
                completed_at,
                actual_duration_minutes,
                difficulty_rating,
                pain_level,
                workouts (
                  id,
                  workout_name,
                  workout_type,
                  exercises,
                  estimated_duration_minutes,
                  difficulty,
                  equipment_needed
                )
              ''')
              .eq('athlete_id', athleteId)
              .eq('scheduled_date', todayStr)
              .maybeSingle();

          if (response != null) {
            return WorkoutCalendarEntry.fromJson(response);
          }
        } catch (e) {
          developer.log('Note: No planned workouts for today: $e');
        }
      }

      return _getMockTodayWorkout();
    } catch (e) {
      developer.log('Error fetching today workout: $e');
      return null;
    }
  }

  // Get tomorrow's workout
  Future<WorkoutCalendarEntry?> getTomorrowWorkout() async {
    try {
      final athleteId = await _getAthleteId();

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStr =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      if (athleteId != null) {
        try {
          final response = await _supabase
              .from('athlete_calendar')
              .select('''
                id,
                athlete_id,
                workout_id,
                scheduled_date,
                scheduled_time,
                status,
                completed_at,
                actual_duration_minutes,
                difficulty_rating,
                pain_level,
                workouts (
                  id,
                  workout_name,
                  workout_type,
                  exercises,
                  estimated_duration_minutes,
                  difficulty,
                  equipment_needed
                )
              ''')
              .eq('athlete_id', athleteId)
              .eq('scheduled_date', tomorrowStr)
              .maybeSingle();

          if (response != null) {
            return WorkoutCalendarEntry.fromJson(response);
          }
        } catch (e) {
          developer.log('Note: No planned workouts for tomorrow: $e');
        }
      }

      return _getMockTomorrowWorkout();
    } catch (e) {
      developer.log('Error fetching tomorrow workout: $e');
      return null;
    }
  }

  // Get yesterday's workout
  Future<WorkoutCalendarEntry?> getYesterdayWorkout() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final athleteId = await _getAthleteId();

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // First, try to get completed GPS activity from yesterday
      if (userId != null) {
        try {
          final gpsActivities = await _supabase
              .from('gps_activities')
              .select()
              .eq('user_id', userId)
              .gte('start_time', '${yesterdayStr}T00:00:00')
              .lte('start_time', '${yesterdayStr}T23:59:59')
              .order('start_time', ascending: false)
              .limit(1);

          if (gpsActivities.isNotEmpty) {
            return WorkoutCalendarEntry.fromGpsActivity(gpsActivities.first);
          }
        } catch (e) {
          developer.log('Note: No GPS activities for yesterday: $e');
        }
      }

      if (athleteId != null) {
        try {
          final response = await _supabase
              .from('athlete_calendar')
              .select('''
                id,
                athlete_id,
                workout_id,
                scheduled_date,
                scheduled_time,
                status,
                completed_at,
                actual_duration_minutes,
                difficulty_rating,
                pain_level,
                workouts (
                  id,
                  workout_name,
                  workout_type,
                  exercises,
                  estimated_duration_minutes,
                  difficulty,
                  equipment_needed
                )
              ''')
              .eq('athlete_id', athleteId)
              .eq('scheduled_date', yesterdayStr)
              .maybeSingle();

          if (response != null) {
            return WorkoutCalendarEntry.fromJson(response);
          }
        } catch (e) {
          developer.log('Note: No planned workouts for yesterday: $e');
        }
      }

      return null;
    } catch (e) {
      developer.log('Error fetching yesterday workout: $e');
      return null;
    }
  }

  // Mark workout as completed
  Future<bool> markWorkoutComplete({
    required String calendarId,
    required int durationMinutes,
    required int difficultyRating,
    required int painLevel,
    String? notes,
  }) async {
    try {
      await _supabase.from('athlete_calendar').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
        'actual_duration_minutes': durationMinutes,
        'difficulty_rating': difficultyRating,
        'pain_level': painLevel,
        'athlete_notes': notes,
      }).eq('id', calendarId);

      return true;
    } catch (e) {
      developer.log('Error marking workout complete: $e');
      return false;
    }
  }

  // Skip workout
  Future<bool> skipWorkout(String calendarId, String? reason) async {
    try {
      await _supabase.from('athlete_calendar').update({
        'status': 'skipped',
        'athlete_notes': reason,
      }).eq('id', calendarId);

      return true;
    } catch (e) {
      developer.log('Error skipping workout: $e');
      return false;
    }
  }

  // Reschedule workout
  Future<bool> rescheduleWorkout(String calendarId, DateTime newDate) async {
    try {
      final newDateStr =
          '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';

      await _supabase.from('athlete_calendar').update({
        'scheduled_date': newDateStr,
        'status': 'rescheduled',
      }).eq('id', calendarId);

      return true;
    } catch (e) {
      developer.log('Error rescheduling workout: $e');
      return false;
    }
  }

  // Mock data for testing without authentication
  List<WorkoutCalendarEntry> _getMockPastWorkouts(DateTime month) {
    final now = DateTime.now();
    final List<WorkoutCalendarEntry> mockWorkouts = [];

    // Generate workouts for the past 2 weeks
    for (int i = 14; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      if (date.month == month.month) {
        // Every other day workout pattern
        if (i % 2 == 0) {
          final status =
              i > 1 ? 'completed' : (i == 1 ? 'completed' : 'scheduled');
          mockWorkouts.add(WorkoutCalendarEntry(
            id: 'mock-$i',
            athleteId: 'mock-athlete',
            workoutId: 'mock-workout-$i',
            scheduledDate: date,
            scheduledTime: const TimeOfDay(hour: 9, minute: 0),
            status: status,
            workout: Workout(
              id: 'mock-workout-$i',
              workoutName: i % 6 == 0
                  ? 'Mobility & Recovery'
                  : (i % 4 == 0 ? 'Strength Training' : 'Balance & Prevention'),
              workoutType: 'injury_prevention',
              exercises: [
                Exercise(name: 'Ankle Mobility', sets: 3, reps: 15),
                Exercise(name: 'Hip Strength', sets: 3, reps: 12),
                Exercise(name: 'Single-Leg Balance', sets: 3, reps: 30),
              ],
              estimatedDurationMinutes: 25,
              difficulty: 'moderate',
              equipmentNeeded: ['resistance_band', 'mat'],
            ),
            completedAt: status == 'completed' ? date : null,
            actualDurationMinutes: status == 'completed' ? 23 : null,
            difficultyRating: status == 'completed' ? 3 : null,
          ));
        }
      }
    }

    return mockWorkouts;
  }

  WorkoutCalendarEntry? _getMockTodayWorkout() {
    final today = DateTime.now();
    return WorkoutCalendarEntry(
      id: 'mock-today',
      athleteId: 'mock-athlete',
      workoutId: 'mock-workout-today',
      scheduledDate: today,
      scheduledTime: const TimeOfDay(hour: 9, minute: 0),
      status: 'scheduled',
      workout: Workout(
        id: 'mock-workout-today',
        workoutName: 'Cadence Drills & Mobility',
        workoutType: 'injury_prevention',
        exercises: [
          Exercise(
              name: 'Cadence Drills',
              sets: 4,
              reps: 10,
              notes:
                  'High knees running in place, focus on quick foot turnover (180 spm)'),
          Exercise(name: 'Ankle Dorsiflexion Stretch', sets: 3, reps: 15),
          Exercise(name: 'Hip Flexor Stretch', sets: 3, reps: 30),
          Exercise(name: 'Single-Leg Balance', sets: 3, reps: 45),
        ],
        estimatedDurationMinutes: 25,
        difficulty: 'moderate',
        equipmentNeeded: ['mat'],
      ),
    );
  }

  WorkoutCalendarEntry? _getMockTomorrowWorkout() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return WorkoutCalendarEntry(
      id: 'mock-tomorrow',
      athleteId: 'mock-athlete',
      workoutId: 'mock-workout-tomorrow',
      scheduledDate: tomorrow,
      scheduledTime: const TimeOfDay(hour: 9, minute: 0),
      status: 'scheduled',
      workout: Workout(
        id: 'mock-workout-tomorrow',
        workoutName: 'Strength & Core Stability',
        workoutType: 'injury_prevention',
        exercises: [
          Exercise(name: 'Single-Leg Glute Bridge', sets: 3, reps: 12),
          Exercise(name: 'Clamshells', sets: 3, reps: 15),
          Exercise(name: 'Plank Hold', sets: 3, reps: 60),
          Exercise(name: 'Dead Bug', sets: 3, reps: 10),
        ],
        estimatedDurationMinutes: 30,
        difficulty: 'moderate',
        equipmentNeeded: ['mat', 'resistance_band'],
      ),
    );
  }
}
