import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;

  // Get current user ID (mock for now)
  static String _getCurrentUserId() {
    // TODO: Replace with actual Supabase auth user ID
    // For now, return a mock user ID
    return 'mock_user_${DateTime.now().day}';
  }

  // Save workout (manual or GPS)
  static Future<void> saveWorkout({
    required double distanceKm,
    required int durationMinutes,
    required String activityType,
    int? rpe,
    String? notes,
    List<Map<String, dynamic>>? gpsData,
  }) async {
    try {
      final userId = _getCurrentUserId();
      
      // Calculate average pace if distance and duration are available
      String? avgPace;
      if (distanceKm > 0 && durationMinutes > 0) {
        final paceMinPerKm = durationMinutes / distanceKm;
        final paceMin = paceMinPerKm.floor();
        final paceSec = ((paceMinPerKm - paceMin) * 60).round();
        avgPace = '$paceMin:${paceSec.toString().padLeft(2, '0')}/km';
      }

      final workoutData = {
        'athlete_id': userId,
        'activity_date': DateTime.now().toIso8601String(),
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
        'activity_type': activityType,
        'rpe': rpe,
        'notes': notes,
        'avg_pace': avgPace,
        'source': 'manual',
        'raw_data': gpsData != null ? {'gps_route': gpsData} : null,
      };

      await supabase.from('completed_activities').insert(workoutData);
    } catch (e) {
      throw Exception('Failed to save workout: $e');
    }
  }

  // Get dashboard data
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final userId = _getCurrentUserId();
      
      // Get user profile
      final profileResponse = await supabase
          .from('athletes')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Get latest assessment
      final assessmentResponse = await supabase
          .from('assessments')
          .select()
          .eq('athlete_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Get weekly distance
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      
      final weeklyResponse = await supabase
          .from('completed_activities')
          .select('distance_km')
          .eq('athlete_id', userId)
          .gte('activity_date', startOfWeek.toIso8601String());

      double weeklyDistance = 0;
      if (weeklyResponse != null) {
        for (var row in weeklyResponse as List) {
          weeklyDistance += (row['distance_km'] as num?)?.toDouble() ?? 0;
        }
      }

      // Get monthly distance
      final startOfMonth = DateTime(now.year, now.month, 1);
      final monthlyResponse = await supabase
          .from('completed_activities')
          .select('distance_km')
          .eq('athlete_id', userId)
          .gte('activity_date', startOfMonth.toIso8601String());

      double monthlyDistance = 0;
      int totalWorkouts = 0;
      if (monthlyResponse != null) {
        final activities = monthlyResponse as List;
        totalWorkouts = activities.length;
        for (var row in activities) {
          monthlyDistance += (row['distance_km'] as num?)?.toDouble() ?? 0;
        }
      }

      // Get total distance (all time)
      final totalResponse = await supabase
          .from('completed_activities')
          .select('distance_km')
          .eq('athlete_id', userId);

      double totalDistance = 0;
      if (totalResponse != null) {
        for (var row in totalResponse as List) {
          totalDistance += (row['distance_km'] as num?)?.toDouble() ?? 0;
        }
      }

      // Calculate streak (consecutive days with activities)
      int streak = 0;
      DateTime checkDate = DateTime.now();
      
      for (int i = 0; i < 365; i++) {
        final dateStr = checkDate.toIso8601String().split('T')[0];
        
        final dayResponse = await supabase
            .from('completed_activities')
            .select('id')
            .eq('athlete_id', userId)
            .gte('activity_date', '$dateStr 00:00:00')
            .lte('activity_date', '$dateStr 23:59:59')
            .limit(1);

        if (dayResponse != null && (dayResponse as List).isNotEmpty) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return {
        'name': profileResponse?['name'] ?? 'Runner',
        'email': profileResponse?['email'] ?? '',
        'aifri_score': assessmentResponse?['aifri_score'] ?? 0,
        'weekly_distance': weeklyDistance,
        'monthly_distance': monthlyDistance,
        'total_distance': totalDistance,
        'total_workouts': totalWorkouts,
        'streak': streak,
        'workout_title': 'Easy Run',
        'workout_description': '5 km at easy pace',
      };
    } catch (e) {
      // Return mock data if Supabase fails
      return {
        'name': 'Runner',
        'email': 'runner@example.com',
        'aifri_score': 335,
        'weekly_distance': 37.0,
        'monthly_distance': 142.5,
        'total_distance': 500.0,
        'total_workouts': 45,
        'streak': 18,
        'workout_title': 'Easy Run',
        'workout_description': '5 km at easy pace',
      };
    }
  }

  // Get workout history
  static Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    try {
      final userId = _getCurrentUserId();

      final response = await supabase
          .from('completed_activities')
          .select()
          .eq('athlete_id', userId)
          .order('activity_date', ascending: false)
          .limit(100);

      if (response == null) return [];
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Return mock data if Supabase fails
      return [
        {
          'id': '1',
          'activity_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'distance_km': 5.2,
          'duration_minutes': 32,
          'activity_type': 'Run',
          'rpe': 6,
          'avg_pace': '6:09/km',
          'notes': 'Felt good, easy pace',
        },
        {
          'id': '2',
          'activity_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'distance_km': 8.5,
          'duration_minutes': 55,
          'activity_type': 'Run',
          'rpe': 7,
          'avg_pace': '6:28/km',
          'notes': 'Long run, felt strong',
        },
        {
          'id': '3',
          'activity_date': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
          'distance_km': 3.0,
          'duration_minutes': 20,
          'activity_type': 'Strength',
          'rpe': 8,
          'notes': 'Circuit training',
        },
      ];
    }
  }

  // Get latest assessment
  static Future<Map<String, dynamic>?> getLatestAssessment() async {
    try {
      final userId = _getCurrentUserId();

      final response = await supabase
          .from('assessments')
          .select()
          .eq('athlete_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Get athlete profile
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final userId = _getCurrentUserId();

      final response = await supabase
          .from('athletes')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Update athlete profile
  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final userId = _getCurrentUserId();

      await supabase
          .from('athletes')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get HR zones
  static Future<Map<String, dynamic>?> getHRZones() async {
    try {
      final userId = _getCurrentUserId();

      final response = await supabase
          .from('hr_zones')
          .select()
          .eq('athlete_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Get today's scheduled workout
  static Future<Map<String, dynamic>?> getTodaysWorkout() async {
    try {
      final userId = _getCurrentUserId();
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await supabase
          .from('scheduled_workouts')
          .select('''
            *,
            workout_templates (
              name,
              description,
              hr_zones,
              duration_minutes
            )
          ''')
          .eq('athlete_id', userId)
          .eq('scheduled_date', today)
          .eq('status', 'scheduled')
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Get upcoming workouts (next 7 days)
  static Future<List<Map<String, dynamic>>> getUpcomingWorkouts() async {
    try {
      final userId = _getCurrentUserId();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final nextWeek = DateTime.now()
          .add(const Duration(days: 6))
          .toIso8601String()
          .split('T')[0];

      final response = await supabase
          .from('scheduled_workouts')
          .select('''
            *,
            workout_templates (
              protocol,
              name,
              duration_minutes
            )
          ''')
          .eq('athlete_id', userId)
          .gte('scheduled_date', today)
          .lte('scheduled_date', nextWeek)
          .order('scheduled_date', ascending: true);

      if (response == null) return [];
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  // Get statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final userId = _getCurrentUserId();
      
      // Get all activities for calculations
      final response = await supabase
          .from('completed_activities')
          .select()
          .eq('athlete_id', userId);

      if (response == null || (response as List).isEmpty) {
        return {
          'total_workouts': 0,
          'total_distance': 0.0,
          'total_duration': 0,
          'avg_distance': 0.0,
          'avg_duration': 0,
        };
      }

      final activities = response as List;
      double totalDistance = 0;
      int totalDuration = 0;

      for (var activity in activities) {
        totalDistance += (activity['distance_km'] as num?)?.toDouble() ?? 0;
        totalDuration += (activity['duration_minutes'] as int?) ?? 0;
      }

      return {
        'total_workouts': activities.length,
        'total_distance': totalDistance,
        'total_duration': totalDuration,
        'avg_distance': totalDistance / activities.length,
        'avg_duration': totalDuration ~/ activities.length,
      };
    } catch (e) {
      return {
        'total_workouts': 0,
        'total_distance': 0.0,
        'total_duration': 0,
        'avg_distance': 0.0,
        'avg_duration': 0,
      };
    }
  }

  // Get device connections
  static Future<List<Map<String, dynamic>>> getDeviceConnections() async {
    try {
      final userId = _getCurrentUserId();

      final response = await supabase
          .from('device_connections')
          .select()
          .eq('athlete_id', userId);

      if (response == null) return [];
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }
}
