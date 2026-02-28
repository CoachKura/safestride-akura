// Run Session Service
// Manages GPS-tracked running sessions and syncs to Strava

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/run_session.dart';
import 'strava_session_service.dart';
import 'dart:developer' as developer;

class RunSessionService {
  static final _supabase = Supabase.instance.client;

  // Save run session to Supabase
  static Future<bool> saveSession(RunSession session) async {
    try {
      final data = session.toJson();

      await _supabase.from('run_sessions').upsert(data);

      developer.log('Run session saved: ${session.id}');
      return true;
    } catch (e) {
      developer.log('Error saving run session: $e');
      return false;
    }
  }

  // Load user's run sessions
  static Future<List<RunSession>> loadUserSessions({
    String? userId,
    int limit = 20,
  }) async {
    try {
      final uid = userId ?? _supabase.auth.currentUser?.id;
      if (uid == null) return [];

      final response = await _supabase
          .from('run_sessions')
          .select()
          .eq('user_id', uid)
          .order('start_time', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => RunSession.fromJson(json))
          .toList();
    } catch (e) {
      developer.log('Error loading run sessions: $e');
      return [];
    }
  }

  // Upload completed run to Strava
  static Future<Map<String, dynamic>?> uploadToStrava(
      RunSession session) async {
    try {
      // Check if already uploaded
      if (session.isUploaded && session.stravaActivityId != null) {
        developer.log('Session already uploaded to Strava');
        return {'success': false, 'message': 'Already uploaded'};
      }

      // Get Strava access token
      final stravaSession = await StravaSessionService.load();
      if (stravaSession == null) {
        return {'success': false, 'message': 'No Strava session found'};
      }

      // Note: Convert route to polyline format in future
      // final routePoints = session.route
      //     .map((p) => '${p.latLng.latitude},${p.latLng.longitude}')
      //     .join(';');

      // Prepare activity data for Strava API
      final activityData = {
        'name': session.workoutName ?? 'SafeStride Run',
        'type': 'Run',
        'sport_type': 'Run',
        'start_date_local': session.startTime.toIso8601String(),
        'elapsed_time': session.totalSeconds,
        'distance': session.distanceMeters,
        'description':
            'Recorded with SafeStride${session.workoutType != null ? ' - ${session.workoutType} workout' : ''}',
        'trainer': false,
        'commute': false,
      };

      // Call Strava API to create activity
      final response = await http.post(
        Uri.parse('https://www.strava.com/api/v3/activities'),
        headers: {
          'Authorization': 'Bearer ${stravaSession.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(activityData),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        final stravaActivityId = result['id'].toString();

        // Update session in Supabase
        await _supabase.from('run_sessions').update({
          'is_uploaded': true,
          'strava_activity_id': stravaActivityId,
          'status': 'uploaded',
        }).eq('id', session.id);

        developer.log('Activity uploaded to Strava: $stravaActivityId');
        return {
          'success': true,
          'strava_activity_id': stravaActivityId,
          'message': 'Successfully uploaded to Strava',
        };
      } else {
        developer.log(
            'Strava upload failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Upload failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      developer.log('Error uploading to Strava: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get session by ID
  static Future<RunSession?> getSessionById(String sessionId) async {
    try {
      final response = await _supabase
          .from('run_sessions')
          .select()
          .eq('id', sessionId)
          .single();

      return RunSession.fromJson(response);
    } catch (e) {
      developer.log('Error getting session: $e');
      return null;
    }
  }

  // Delete session
  static Future<bool> deleteSession(String sessionId) async {
    try {
      await _supabase.from('run_sessions').delete().eq('id', sessionId);
      return true;
    } catch (e) {
      developer.log('Error deleting session: $e');
      return false;
    }
  }

  // Get weekly statistics
  static Future<Map<String, dynamic>> getWeeklyStats({String? userId}) async {
    try {
      final uid = userId ?? _supabase.auth.currentUser?.id;
      if (uid == null) return {};

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr =
          DateTime(weekStart.year, weekStart.month, weekStart.day)
              .toIso8601String();

      final response = await _supabase
          .from('run_sessions')
          .select()
          .eq('user_id', uid)
          .gte('start_time', weekStartStr)
          .eq('status', 'completed');

      final sessions =
          (response as List).map((json) => RunSession.fromJson(json)).toList();

      double totalDistance = 0;
      int totalDuration = 0;
      int totalRuns = sessions.length;

      for (var session in sessions) {
        totalDistance += session.distanceMeters / 1000; // Convert to km
        totalDuration += session.durationSeconds;
      }

      final avgPace = totalDuration > 0 && totalDistance > 0
          ? (totalDuration / 60) / totalDistance
          : 0.0;

      return {
        'total_runs': totalRuns,
        'total_distance_km': totalDistance,
        'total_duration_seconds': totalDuration,
        'avg_pace_min_per_km': avgPace,
      };
    } catch (e) {
      developer.log('Error getting weekly stats: $e');
      return {};
    }
  }

  // Format pace for display
  static String formatPace(double? paceMinPerKm) {
    if (paceMinPerKm == null || paceMinPerKm == 0) return '--:--';
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
  }

  // Format duration for display
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Format distance for display
  static String formatDistance(double meters) {
    final km = meters / 1000;
    return km.toStringAsFixed(2);
  }
}
