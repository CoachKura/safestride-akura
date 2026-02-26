import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'gps_data_fetcher.dart';
import 'dart:developer' as developer;

class StravaService {
  // Strava API credentials loaded from .env file
  static final String clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '';
  static final String clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';

  // Redirect URIs with environment and platform-aware defaults
  // Prefer explicit env vars; fall back to Supabase auth callback to match Strava config
  static final String _redirectWeb = dotenv.env['STRAVA_REDIRECT_URI_WEB'] ??
      'https://bdisppaxbvygsspcuymb.supabase.co/auth/v1/callback';
  static final String _redirectApp = dotenv.env['STRAVA_REDIRECT_URI_APP'] ??
      'https://bdisppaxbvygsspcuymb.supabase.co/auth/v1/callback';
  static final String redirectUri = (() {
    final explicit = dotenv.env['STRAVA_REDIRECT_URI'];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return kIsWeb ? _redirectWeb : _redirectApp;
  })();

  // Strava API endpoints
  static const String authUrl = 'https://www.strava.com/oauth/authorize';
  static const String tokenUrl = 'https://www.strava.com/oauth/token';
  static const String activitiesUrl =
      'https://www.strava.com/api/v3/athlete/activities';
  static const String athleteUrl = 'https://www.strava.com/api/v3/athlete';

  /// Step 1: Initiate OAuth flow
  /// Opens Strava authorization page in browser
  Future<bool> connectStrava() async {
    try {
      final Uri authUri = Uri.parse('$authUrl'
          '?client_id=$clientId'
          '&response_type=code'
          '&redirect_uri=$redirectUri'
          '&approval_prompt=force'
          '&scope=activity:read_all,activity:read,profile:read_all');

      developer.log('Strava OAuth URL: $authUri');

      // Try to launch with external application mode
      final launched = await launchUrl(
        authUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback: try with platform default
        return await launchUrl(authUri);
      }

      return launched;
    } catch (e) {
      developer.log('Error launching Strava auth: $e');
      return false;
    }
  }

  /// Get Strava authorization URL for manual connection
  String getAuthorizationUrl() {
    return '$authUrl'
        '?client_id=$clientId'
        '&response_type=code'
        '&redirect_uri=$redirectUri'
        '&approval_prompt=force'
        '&scope=activity:read_all,activity:read,profile:read_all';
  }

  /// Step 2: Exchange authorization code for access token
  /// Called after user authorizes the app
  Future<bool> handleAuthorizationCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Save tokens to Supabase profiles table
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return false;

        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          data['expires_at'] * 1000,
        );

        await Supabase.instance.client.from('profiles').update({
          'strava_access_token': data['access_token'],
          'strava_refresh_token': data['refresh_token'],
          'strava_athlete_id': data['athlete']['id'],
          'strava_connected_at': DateTime.now().toIso8601String(),
          'strava_expires_at': expiresAt.toIso8601String(),
        }).eq('id', userId);

        // Keep gps_connections in sync so activity detail lookups work
        await GPSDataFetcher().storeAccessToken(
          platform: GPSPlatform.strava,
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresAt: expiresAt,
        );

        // Immediately sync activities after connecting
        await syncActivities();

        return true;
      }

      developer.log('Strava token exchange failed: ${response.statusCode}');
      return false;
    } catch (e) {
      developer.log('Error exchanging Strava code: $e');
      return false;
    }
  }

  /// Refresh access token if expired
  Future<String?> _getValidAccessToken() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select(
              'strava_access_token, strava_refresh_token, strava_expires_at')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['strava_access_token'] == null) {
        return null;
      }

      // Check if token is expired
      final expiresAt = DateTime.parse(profile['strava_expires_at']);
      if (DateTime.now().isBefore(expiresAt)) {
        return profile['strava_access_token'];
      }

      // Token expired, refresh it
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': profile['strava_refresh_token'],
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update tokens in database
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          data['expires_at'] * 1000,
        );

        await Supabase.instance.client.from('profiles').update({
          'strava_access_token': data['access_token'],
          'strava_refresh_token': data['refresh_token'],
          'strava_expires_at': expiresAt.toIso8601String(),
        }).eq('id', userId);

        // Refresh token cache used by gps detail fetcher
        await GPSDataFetcher().storeAccessToken(
          platform: GPSPlatform.strava,
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresAt: expiresAt,
        );

        return data['access_token'];
      }

      return null;
    } catch (e) {
      developer.log('Error refreshing token: $e');
      return null;
    }
  }

  /// Step 3: Sync activities from Strava
  /// Fetches recent activities and imports them as workouts
  Future<int> syncActivities({int perPage = 100}) async {
    try {
      final accessToken = await _getValidAccessToken();
      if (accessToken == null) {
        throw Exception('Not connected to Strava or token expired');
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get activities from the last 14 days to ensure we catch recent workouts
      final after = (DateTime.now()
                  .subtract(const Duration(days: 14))
                  .millisecondsSinceEpoch ~/
              1000)
          .toString();

      // Fetch activities from Strava API with date filter
      final response = await http.get(
        Uri.parse('$activitiesUrl?per_page=$perPage&after=$after'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        developer.log('Strava API error: ${response.statusCode}');
        return 0;
      }

      final activities = json.decode(response.body) as List;
      developer.log(
          'Fetched ${activities.length} activities from Strava (last 14 days)');

      // DEBUG: Log first activity details
      if (activities.isNotEmpty) {
        final firstActivity = activities.first;
        developer.log(
            'DEBUG: Most recent activity: ${firstActivity['name']} on ${firstActivity['start_date']}');
        developer.log(
            'DEBUG: Activity ID: ${firstActivity['id']}, Type: ${firstActivity['type']}');
      }

      int syncedCount = 0;

      // Import each activity as a workout
      for (var activity in activities) {
        try {
          // Check if activity already exists using external_id
          final existing = await Supabase.instance.client
              .from('workouts')
              .select('id')
              .eq('external_id', activity['id'].toString())
              .eq('synced_from', 'strava')
              .maybeSingle();

          if (existing != null) {
            developer.log(
                'DEBUG: Skipping duplicate activity: ${activity['name']} (${activity['id']})');
            continue; // Skip if already imported
          }

          // Map Strava activity type to our activity types
          String workoutType = _mapStravaWorkoutType(activity['type']);

          // Calculate average pace (min/km) from speed
          double? avgPace;
          if (activity['average_speed'] != null &&
              activity['average_speed'] > 0) {
            // Convert m/s to min/km: (1000 / speed) / 60
            avgPace = (1000 / activity['average_speed']) / 60;
          }

          // Prepare GPS route data from polyline
          Map<String, dynamic>? routeData;
          if (activity['map'] != null &&
              activity['map']['summary_polyline'] != null) {
            routeData = {
              'polyline': activity['map']['summary_polyline'],
              'type': 'strava_polyline',
            };
          }

          // Insert new workout with complete data
          await Supabase.instance.client.from('workouts').insert({
            'athlete_id': userId,
            'workout_type': workoutType,
            'title': activity['name'],
            'description': 'Synced from Strava',
            'distance_km': (activity['distance'] ?? 0) / 1000, // m to km
            'duration_minutes':
                ((activity['moving_time'] ?? 0) / 60).round(), // s to min
            'avg_pace_min_per_km': avgPace,
            'avg_heart_rate': activity['average_heartrate']?.round(),
            'max_heart_rate': activity['max_heartrate']?.round(),
            'calories_burned': activity['calories']?.round(),
            'elevation_gain_m': activity['total_elevation_gain']?.round(),
            'route_data': routeData,
            'workout_date': activity['start_date'],
            'created_at': activity['start_date'],
            'is_completed': true,
            'synced_from': 'strava',
            'external_id': activity['id'].toString(),
            'sync_timestamp': DateTime.now().toIso8601String(),
          });

          syncedCount++;
          developer.log(
              'DEBUG: Successfully imported: ${activity['name']} (${activity['id']})');
        } catch (e) {
          developer.log('Error importing activity ${activity['id']}: $e');
        }
      }

      developer
          .log('DEBUG: Sync complete - imported $syncedCount new activities');
      return syncedCount;
    } catch (e) {
      developer.log('Error syncing Strava activities: $e');
      return 0;
    }
  }

  /// Map Strava activity types to our workout types
  String _mapStravaWorkoutType(String stravaType) {
    const typeMapping = {
      'Run': 'run',
      'TrailRun': 'run',
      'VirtualRun': 'run',
      'Ride': 'cycle',
      'VirtualRide': 'cycle',
      'MountainBikeRide': 'cycle',
      'GravelRide': 'cycle',
      'Swim': 'other',
      'Walk': 'walk',
      'Hike': 'walk',
      'Workout': 'other',
      'WeightTraining': 'strength',
      'Yoga': 'yoga',
      'CrossFit': 'strength',
    };

    return typeMapping[stravaType] ?? 'other';
  }

  /// Check if user has Strava connected
  Future<bool> isConnected() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('strava_access_token')
          .eq('id', userId)
          .maybeSingle();

      return profile?['strava_access_token'] != null;
    } catch (e) {
      developer.log('Error checking Strava connection: $e');
      return false;
    }
  }

  /// Get Strava connection info
  Future<Map<String, dynamic>?> getConnectionInfo() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('strava_athlete_id, strava_connected_at')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null || profile['strava_athlete_id'] == null) {
        return null;
      }

      return {
        'athlete_id': profile['strava_athlete_id'],
        'connected_at': profile['strava_connected_at'],
      };
    } catch (e) {
      developer.log('Error getting connection info: $e');
      return null;
    }
  }

  /// Disconnect Strava
  Future<bool> disconnect() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      await Supabase.instance.client.from('profiles').update({
        'strava_access_token': null,
        'strava_refresh_token': null,
        'strava_athlete_id': null,
        'strava_connected_at': null,
        'strava_expires_at': null,
      }).eq('id', userId);

      // Also clear gps_connections so detail views stop using stale tokens
      await GPSDataFetcher().disconnectPlatform(GPSPlatform.strava);

      return true;
    } catch (e) {
      developer.log('Error disconnecting Strava: $e');
      return false;
    }
  }
}
