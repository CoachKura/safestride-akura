import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StravaService {
  // Strava API credentials loaded from .env file
  static final String clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '';
  static final String clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';
  
  // Production web callback that redirects to app (works everywhere)
  static const String redirectUri = 'https://akura.in/strava-callback.html';
  
  // Strava API endpoints
  static const String authUrl = 'https://www.strava.com/oauth/authorize';
  static const String tokenUrl = 'https://www.strava.com/oauth/token';
  static const String activitiesUrl = 'https://www.strava.com/api/v3/athlete/activities';
  static const String athleteUrl = 'https://www.strava.com/api/v3/athlete';
  
  /// Step 1: Initiate OAuth flow
  /// Opens Strava authorization page in browser
  Future<bool> connectStrava() async {
    try {
      final Uri authUri = Uri.parse(
        '$authUrl'
        '?client_id=$clientId'
        '&response_type=code'
        '&redirect_uri=$redirectUri'
        '&approval_prompt=force'
        '&scope=activity:read_all,activity:read,profile:read_all'
      );
      
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
      print('Error launching Strava auth: $e');
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
        
        await Supabase.instance.client.from('profiles').update({
          'strava_access_token': data['access_token'],
          'strava_refresh_token': data['refresh_token'],
          'strava_athlete_id': data['athlete']['id'],
          'strava_connected_at': DateTime.now().toIso8601String(),
          'strava_expires_at': DateTime.fromMillisecondsSinceEpoch(
            data['expires_at'] * 1000,
          ).toIso8601String(),
        }).eq('id', userId);
        
        // Immediately sync activities after connecting
        await syncActivities();
        
        return true;
      }
      
      print('Strava token exchange failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error exchanging Strava code: $e');
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
          .select('strava_access_token, strava_refresh_token, strava_expires_at')
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
        await Supabase.instance.client.from('profiles').update({
          'strava_access_token': data['access_token'],
          'strava_refresh_token': data['refresh_token'],
          'strava_expires_at': DateTime.fromMillisecondsSinceEpoch(
            data['expires_at'] * 1000,
          ).toIso8601String(),
        }).eq('id', userId);
        
        return data['access_token'];
      }
      
      return null;
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }
  
  /// Step 3: Sync activities from Strava
  /// Fetches recent activities and imports them as workouts
  Future<int> syncActivities({int perPage = 30}) async {
    try {
      final accessToken = await _getValidAccessToken();
      if (accessToken == null) {
        throw Exception('Not connected to Strava or token expired');
      }
      
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 0;
      
      // Fetch activities from Strava API
      final response = await http.get(
        Uri.parse('$activitiesUrl?per_page=$perPage'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      
      if (response.statusCode != 200) {
        print('Strava API error: ${response.statusCode}');
        return 0;
      }
      
      final activities = json.decode(response.body) as List;
      int syncedCount = 0;
      
      // Import each activity as a workout
      for (var activity in activities) {
        try {
          // Check if activity already exists
          final existing = await Supabase.instance.client
              .from('workouts')
              .select('id')
              .eq('strava_activity_id', activity['id'])
              .maybeSingle();
          
          if (existing != null) continue; // Skip if already imported
          
          // Map Strava activity type to our activity types
          String activityType = _mapStravaActivityType(activity['type']);
          
          // Insert new workout
          await Supabase.instance.client.from('workouts').insert({
            'user_id': userId,
            'activity_type': activityType,
            'distance': (activity['distance'] ?? 0) / 1000, // m to km
            'duration': ((activity['moving_time'] ?? 0) / 60).round(), // s to min
            'notes': 'Synced from Strava: ${activity['name']}',
            'created_at': activity['start_date'],
            'strava_activity_id': activity['id'],
          });
          
          syncedCount++;
        } catch (e) {
          print('Error importing activity ${activity['id']}: $e');
        }
      }
      
      return syncedCount;
    } catch (e) {
      print('Error syncing Strava activities: $e');
      return 0;
    }
  }
  
  /// Map Strava activity types to our activity types
  String _mapStravaActivityType(String stravaType) {
    const typeMapping = {
      'Run': 'Easy Run',
      'Ride': 'Cycling',
      'Swim': 'Swimming',
      'Walk': 'Walking',
      'Hike': 'Hiking',
      'Workout': 'Other',
      'WeightTraining': 'Strength Training',
      'Yoga': 'Yoga',
    };
    
    return typeMapping[stravaType] ?? 'Other';
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
      print('Error checking Strava connection: $e');
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
      print('Error getting connection info: $e');
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
      
      return true;
    } catch (e) {
      print('Error disconnecting Strava: $e');
      return false;
    }
  }
}
