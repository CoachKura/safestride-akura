// lib/services/garmin_oauth_service.dart
//
// Garmin Connect OAuth API Integration
// Handles authentication, activity sync, and workout push
// 
// NOTE: Requires Garmin API approval - apply at developer.garmin.com
// This is separate from garmin_connect_service.dart (local device connection)

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class GarminOAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Garmin OAuth Configuration
  // TODO: Replace with actual values after Garmin API approval
  static const String _clientId = 'YOUR_GARMIN_CLIENT_ID';
  static const String _clientSecret = 'YOUR_GARMIN_CLIENT_SECRET';
  static const String _authUrl = 'https://connect.garmin.com/oauthConfirm';
  static const String _tokenUrl = 'https://connectapi.garmin.com/oauth-service/oauth/token';
  static const String _apiBaseUrl = 'https://apis.garmin.com';
  
  // OAuth Scopes
  static const List<String> _scopes = [
    'activity:read',
    'activity:write',
    'workouts:read',
    'workouts:write',
  ];

  /// Check if user has connected Garmin account
  Future<bool> isConnected() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('garmin_connections')
          .select('is_active, token_expires_at')
          .eq('athlete_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return false;

      // Check if token is still valid
      final expiresAt = DateTime.parse(response['token_expires_at']);
      if (expiresAt.isBefore(DateTime.now().add(Duration(hours: 1)))) {
        // Token expires soon, refresh it
        return await refreshToken();
      }

      return true;
    } catch (e) {
      developer.log('Error checking Garmin connection: $e');
      return false;
    }
  }

  /// Get Garmin connection details
  Future<Map<String, dynamic>?> getConnection() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('garmin_connections')
          .select()
          .eq('athlete_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      developer.log('Error getting Garmin connection: $e');
      return null;
    }
  }

  /// Initiate OAuth flow
  /// Returns authorization URL for user to complete in browser
  Future<String> getAuthorizationUrl(String redirectUri) async {
    final params = {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': _scopes.join(' '),
    };

    final uri = Uri.parse(_authUrl).replace(queryParameters: params);
    return uri.toString();
  }

  /// Exchange authorization code for access token
  Future<bool> exchangeCodeForToken(String code, String redirectUri) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Exchange code for token
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode != 200) {
        developer.log('Error exchanging code: ${response.body}');
        return false;
      }

      final tokenData = json.decode(response.body);
      return await _saveTokens(userId, tokenData);
    } catch (e) {
      developer.log('Error in OAuth flow: $e');
      return false;
    }
  }

  /// Save OAuth tokens to database
  Future<bool> _saveTokens(String userId, Map<String, dynamic> tokenData) async {
    try {
      final expiresAt = DateTime.now().add(
        Duration(seconds: tokenData['expires_in'] ?? 3600),
      );

      // Check if connection already exists
      final existing = await _supabase
          .from('garmin_connections')
          .select('id')
          .eq('athlete_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Update existing connection
        await _supabase.from('garmin_connections').update({
          'access_token': tokenData['access_token'],
          'refresh_token': tokenData['refresh_token'],
          'token_expires_at': expiresAt.toIso8601String(),
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
      } else {
        // Create new connection
        await _supabase.from('garmin_connections').insert({
          'athlete_id': userId,
          'garmin_user_id': tokenData['user_id'] ?? 'unknown',
          'access_token': tokenData['access_token'],
          'refresh_token': tokenData['refresh_token'],
          'token_expires_at': expiresAt.toIso8601String(),
          'is_active': true,
        });
      }

      return true;
    } catch (e) {
      developer.log('Error saving tokens: $e');
      return false;
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    try {
      final connection = await getConnection();
      if (connection == null) return false;

      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': connection['refresh_token'],
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (response.statusCode != 200) {
        developer.log('Error refreshing token: ${response.body}');
        return false;
      }

      final tokenData = json.decode(response.body);
      return await _saveTokens(connection['athlete_id'], tokenData);
    } catch (e) {
      developer.log('Error refreshing token: $e');
      return false;
    }
  }

  /// Get valid access token (refreshes if needed)
  Future<String?> _getAccessToken() async {
    final connection = await getConnection();
    if (connection == null) return null;

    final expiresAt = DateTime.parse(connection['token_expires_at']);
    if (expiresAt.isBefore(DateTime.now().add(Duration(minutes: 5)))) {
      // Token expires soon, refresh it
      final refreshed = await refreshToken();
      if (!refreshed) return null;

      // Get updated connection
      final updated = await getConnection();
      return updated?['access_token'];
    }

    return connection['access_token'];
  }

  /// Sync recent activities from Garmin Connect
  Future<List<Map<String, dynamic>>> syncActivities({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('Not connected to Garmin');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Default to last 30 days
      startDate ??= DateTime.now().subtract(Duration(days: 30));
      endDate ??= DateTime.now();

      // Get activities from Garmin API
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/activitylist-service/activities/search/activities').replace(
          queryParameters: {
            'startDate': startDate.toIso8601String(),
            'endDate': endDate.toIso8601String(),
            'limit': limit.toString(),
          },
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        developer.log('Error fetching activities: ${response.body}');
        return [];
      }

      final activities = json.decode(response.body) as List;
      final syncedActivities = <Map<String, dynamic>>[];

      // Save activities to database
      for (final activity in activities) {
        final activityData = {
          'athlete_id': userId,
          'garmin_activity_id': activity['activityId'],
          'activity_type': activity['activityType']['typeKey'],
          'start_time': activity['startTimeLocal'],
          'duration': activity['duration'],
          'distance': activity['distance'],
          'average_heart_rate': activity['averageHR'],
          'max_heart_rate': activity['maxHR'],
          'average_pace': activity['avgSpeed'],
          'calories': activity['calories'],
          'elevation_gain': activity['elevationGain'],
          'training_effect': activity['aerobicTrainingEffect'],
          'vo2_max': activity['vO2MaxValue'],
          'raw_data': activity,
        };

        // Check if activity already exists
        final existing = await _supabase
            .from('garmin_activities')
            .select('id')
            .eq('garmin_activity_id', activity['activityId'])
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('garmin_activities').insert(activityData);
          syncedActivities.add(activityData);
        }
      }

      // Update last sync time
      await _supabase.from('garmin_connections').update({
        'last_sync_at': DateTime.now().toIso8601String(),
      }).eq('athlete_id', userId);

      developer.log('Synced ${syncedActivities.length} new activities from Garmin');
      return syncedActivities;
    } catch (e) {
      developer.log('Error syncing activities: $e');
      rethrow;
    }
  }

  /// Get user's Garmin devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('Not connected to Garmin');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get devices from Garmin API
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/device-service/deviceregistration/devices'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        developer.log('Error fetching devices: ${response.body}');
        return [];
      }

      final devices = json.decode(response.body) as List;

      // Save devices to database
      for (final device in devices) {
        final deviceData = {
          'athlete_id': userId,
          'garmin_device_id': device['deviceId'],
          'device_name': device['deviceName'],
          'device_type': device['deviceTypePk'],
          'firmware_version': device['firmwareVersion'],
          'last_sync_at': device['lastSyncTime'],
          'is_active': true,
        };

        // Upsert device
        await _supabase.from('garmin_devices').upsert(deviceData);
      }

      return devices.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('Error getting devices: $e');
      return [];
    }
  }

  /// Push structured workout to Garmin Connect
  Future<bool> pushWorkout(Map<String, dynamic> workout) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('Not connected to Garmin');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Convert SafeStride workout to Garmin format
      final garminWorkout = _convertToGarminFormat(workout);

      // Push workout to Garmin
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/workout-service/workout'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(garminWorkout),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        developer.log('Error pushing workout: ${response.body}');
        return false;
      }

      final result = json.decode(response.body);

      // Save push record to database
      await _supabase.from('garmin_pushed_workouts').insert({
        'athlete_id': userId,
        'safestride_workout_id': workout['id'],
        'garmin_workout_id': result['workoutId'],
        'workout_name': workout['name'],
        'workout_type': workout['type'],
        'scheduled_date': workout['scheduled_date'],
        'push_status': 'success',
        'pushed_at': DateTime.now().toIso8601String(),
        'garmin_response': result,
      });

      developer.log('Successfully pushed workout to Garmin');
      return true;
    } catch (e) {
      developer.log('Error pushing workout: $e');

      // Save failed push record
      try {
        await _supabase.from('garmin_pushed_workouts').insert({
          'athlete_id': _supabase.auth.currentUser?.id,
          'safestride_workout_id': workout['id'],
          'workout_name': workout['name'],
          'workout_type': workout['type'],
          'scheduled_date': workout['scheduled_date'],
          'push_status': 'failed',
          'pushed_at': DateTime.now().toIso8601String(),
          'garmin_response': {'error': e.toString()},
        });
      } catch (_) {}

      return false;
    }
  }

  /// Convert SafeStride workout format to Garmin format
  Map<String, dynamic> _convertToGarminFormat(Map<String, dynamic> workout) {
    // TODO: Implement proper conversion based on Garmin API spec
    // This is a simplified example
    return {
      'workoutName': workout['name'],
      'sportTypeKey': 'running',
      'workoutSegments': [
        // Convert SafeStride steps to Garmin workout segments
        // Example: warmup, intervals, cooldown
      ],
    };
  }

  /// Disconnect Garmin account
  Future<void> disconnect() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('garmin_connections')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('athlete_id', userId);

      developer.log('Disconnected from Garmin');
    } catch (e) {
      developer.log('Error disconnecting Garmin: $e');
      rethrow;
    }
  }

  /// Get connection status and statistics
  Future<Map<String, dynamic>> getConnectionStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'connected': false};
      }

      final connection = await getConnection();
      if (connection == null) {
        return {'connected': false};
      }

      // Get activity count
      final activityCount = await _supabase
          .from('garmin_activities')
          .select('*')
          .eq('athlete_id', userId);

      // Get device count
      final deviceCount = await _supabase
          .from('garmin_devices')
          .select('*')
          .eq('athlete_id', userId)
          .eq('is_active', true);

      return {
        'connected': true,
        'last_sync': connection['last_sync_at'],
        'activity_count': activityCount.length,
        'device_count': deviceCount.length,
        'garmin_user_id': connection['garmin_user_id'],
      };
    } catch (e) {
      developer.log('Error getting connection status: $e');
      return {'connected': false, 'error': e.toString()};
    }
  }
}
