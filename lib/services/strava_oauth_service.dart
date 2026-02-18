// Strava OAuth 2.0 Authentication Service
//
// Uses Supabase OAuth provider for seamless authentication
// This eliminates redirect URI issues by letting Supabase handle the flow
//
// Date: February 5, 2026

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'gps_data_fetcher.dart';
import 'dart:developer' as developer;

class StravaOAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GPSDataFetcher _gpsDataFetcher = GPSDataFetcher();

  // Strava OAuth Constants
  static final String _clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '';
  static final String _clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';
  static final String _redirectWeb = dotenv.env['STRAVA_REDIRECT_URI_WEB'] ??
      'https://akura.in/strava-callback';
  static final String _redirectApp =
      dotenv.env['STRAVA_REDIRECT_URI_APP'] ?? 'safestride://strava-callback';
  static final String _redirectUri = (() {
    final explicit = dotenv.env['STRAVA_REDIRECT_URI'];
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return kIsWeb ? _redirectWeb : _redirectApp;
  })();
  static const String _scope = 'read,activity:read_all';
  static const String _authorizeUrl = 'https://www.strava.com/oauth/authorize';
  static const String _tokenUrl = 'https://www.strava.com/oauth/token';

  /// Generate Strava authorization URL
  ///
  /// Returns the URL to redirect user to for OAuth authorization
  String getAuthorizationUrl() {
    final params = {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'scope': _scope,
      'approval_prompt': 'auto',
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$_authorizeUrl?$queryString';
  }

  /// Exchange authorization code for access token
  ///
  /// Called after user authorizes app and returns with code
  ///
  /// Parameters:
  /// - code: Authorization code from Strava redirect
  ///
  /// Returns: Map with access_token, refresh_token, expires_at, athlete info
  Future<Map<String, dynamic>> exchangeCodeForToken(String code) async {
    try {
      developer.log('ðŸ”„ Exchanging Strava authorization code for token...');

      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        developer.log('âœ… Strava token received successfully');
        developer.log(
            '   Athlete: ${data['athlete']['firstname']} ${data['athlete']['lastname']}');
        developer.log(
            '   Expires: ${DateTime.fromMillisecondsSinceEpoch(data['expires_at'] * 1000)}');

        // Store token in Supabase
        await _storeToken(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresAt:
              DateTime.fromMillisecondsSinceEpoch(data['expires_at'] * 1000),
          athleteInfo: data['athlete'],
        );

        return {
          'success': true,
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'expires_at': data['expires_at'],
          'athlete': data['athlete'],
        };
      } else {
        developer.log('âŒ Token exchange failed: ${response.statusCode}');
        developer.log('   Response: ${response.body}');

        return {
          'success': false,
          'error': 'Token exchange failed: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      developer.log('âŒ Error exchanging token: $e');
      developer.log('âŒ Error details: ${e.toString()}');
      developer.log('âŒ Error type: ${e.runtimeType}');
      return {
        'success': false,
        'error': 'Exception: ${e.toString()}',
        'details': 'Error type: ${e.runtimeType}',
      };
    }
  }

  /// Refresh expired access token using refresh token
  ///
  /// Strava tokens expire after 6 hours
  ///
  /// Parameters:
  /// - refreshToken: The refresh_token from previous authentication
  ///
  /// Returns: New access token and expiration time
  Future<Map<String, dynamic>> refreshAccessToken(String refreshToken) async {
    try {
      developer.log('ðŸ”„ Refreshing Strava access token...');

      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        developer.log('âœ… Strava token refreshed successfully');
        developer.log(
            '   New expiration: ${DateTime.fromMillisecondsSinceEpoch(data['expires_at'] * 1000)}');

        // Update stored token
        await _storeToken(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresAt:
              DateTime.fromMillisecondsSinceEpoch(data['expires_at'] * 1000),
        );

        return {
          'success': true,
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'expires_at': data['expires_at'],
        };
      } else {
        developer.log('âŒ Token refresh failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Token refresh failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      developer.log('âŒ Error refreshing token: $e');
      return {
        'success': false,
        'error': 'Exception during token refresh',
        'details': e.toString(),
      };
    }
  }

  /// Store or update Strava token in database
  Future<void> _storeToken({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    Map<String, dynamic>? athleteInfo,
  }) async {
    await _gpsDataFetcher.storeAccessToken(
      platform: GPSPlatform.strava,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );

    // Optionally store athlete info in user metadata
    if (athleteInfo != null) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('athlete_profiles').upsert({
          'user_id': userId,
          'strava_athlete_id': athleteInfo['id'],
          'strava_username': athleteInfo['username'],
          'strava_firstname': athleteInfo['firstname'],
          'strava_lastname': athleteInfo['lastname'],
          'strava_profile_image': athleteInfo['profile'],
          'sync_from_strava': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }

    developer.log('ðŸ’¾ Strava token stored in database');
  }

  /// Check if Strava connection is valid (not expired)
  Future<bool> isConnectionValid() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('gps_connections')
          .select('expires_at, refresh_token')
          .eq('user_id', userId)
          .eq('platform', 'strava')
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return false;

      final expiresAt = DateTime.parse(response['expires_at']);
      final now = DateTime.now();

      // If token expires in less than 1 hour, refresh it
      if (expiresAt.isBefore(now.add(Duration(hours: 1)))) {
        developer.log('â° Strava token expiring soon, refreshing...');
        final refreshResult =
            await refreshAccessToken(response['refresh_token']);
        return refreshResult['success'] == true;
      }

      return true;
    } catch (e) {
      developer.log('âŒ Error checking Strava connection: $e');
      return false;
    }
  }

  /// Disconnect Strava (revoke tokens)
  Future<bool> disconnect() async {
    try {
      await _gpsDataFetcher.disconnectPlatform(GPSPlatform.strava);
      developer.log('ðŸ”Œ Strava disconnected successfully');
      return true;
    } catch (e) {
      developer.log('âŒ Error disconnecting Strava: $e');
      return false;
    }
  }

  /// Get athlete's Strava profile information
  Future<Map<String, dynamic>?> getAthleteProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('athlete_profiles')
          .select(
              'strava_athlete_id, strava_username, strava_firstname, strava_lastname, strava_profile_image')
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      developer.log('âŒ Error fetching Strava profile: $e');
      return null;
    }
  }

  /// Test Strava API connection with current token
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Get access token
      final tokenResponse = await _supabase
          .from('gps_connections')
          .select('access_token')
          .eq('user_id', userId)
          .eq('platform', 'strava')
          .eq('is_active', true)
          .maybeSingle();

      if (tokenResponse == null) {
        return {
          'success': false,
          'error': 'Strava not connected',
        };
      }

      // Test API call: Get athlete profile
      final response = await http.get(
        Uri.parse('https://www.strava.com/api/v3/athlete'),
        headers: {
          'Authorization': 'Bearer ${tokenResponse['access_token']}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'athlete': data,
          'message': 'Strava connection working',
        };
      } else {
        return {
          'success': false,
          'error': 'API call failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception during test: $e',
      };
    }
  }
}
