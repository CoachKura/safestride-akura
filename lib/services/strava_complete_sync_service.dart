import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Complete Strava Sync Service
///
/// Handles:
/// 1. OAuth flow (connect to Strava)
/// 2. Fetch athlete profile (name, age, weight, height, gender)
/// 3. Fetch ALL activities (paginated, up to 1000+)
/// 4. Calculate Personal Bests (5K, 10K, Half Marathon, Marathon)
/// 5. Calculate total mileage
/// 6. Store everything in Supabase profiles table
/// 7. Background sync for large activity histories
class StravaCompleteSyncService {
  final _supabase = Supabase.instance.client;

  // Strava OAuth Config
  static final String _clientId = dotenv.env['STRAVA_CLIENT_ID'] ?? '162971';
  static final String _clientSecret = dotenv.env['STRAVA_CLIENT_SECRET'] ?? '';
  static final String _redirectUri = kIsWeb
      ? dotenv.env['STRAVA_REDIRECT_URI_WEB'] ??
          'https://akura.in/strava-callback'
      : dotenv.env['STRAVA_REDIRECT_URI_APP'] ?? 'safestride://strava-callback';

  // Strava API Endpoints
  static const String _authorizeUrl = 'https://www.strava.com/oauth/authorize';
  static const String _tokenUrl = 'https://www.strava.com/oauth/token';
  static const String _athleteUrl = 'https://www.strava.com/api/v3/athlete';
  static const String _activitiesUrl =
      'https://www.strava.com/api/v3/athlete/activities';

  /// Initiate Strava OAuth flow
  /// Returns: {'success': true, 'athlete': {...}, 'access_token': '...', ...}
  Future<Map<String, dynamic>> initiateStravaOAuth() async {
    try {
      // 1. Generate authorization URL
      final authUrl = _getAuthorizationUrl();

      // 2. Open WebView/Browser for OAuth (implementation depends on platform)
      // For web: redirect to authUrl
      // For mobile: use webview with url_launcher

      // This is a placeholder - actual implementation would use platform-specific OAuth
      // For now, simulating successful OAuth

      // 3. After OAuth callback, exchange code for token
      // final code = await _waitForOAuthCallback();
      // final tokenResponse = await _exchangeCodeForToken(code);

      // TEMP: Return mock data for development
      return {
        'success': true,
        'athlete': {
          'id': 123456789,
          'firstname': 'Test',
          'lastname': 'Runner',
          'profile':
              'https://dgalywyr863hv.cloudfront.net/pictures/athletes/123456789/medium.jpg',
          'sex': 'M',
          'created_at': '2020-01-01T00:00:00Z',
          'activity_count': 0,
          'total_distance': 0,
        },
        'access_token': 'mock_token',
        'refresh_token': 'mock_refresh',
        'expires_at': DateTime.now()
                .add(const Duration(hours: 6))
                .millisecondsSinceEpoch ~/
            1000,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  String _getAuthorizationUrl() {
    final params = {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'scope': 'read,activity:read_all,profile:read_all', // Full access
      'approval_prompt': 'auto',
    };

    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$_authorizeUrl?$queryString';
  }

  /// Exchange OAuth code for access token
  Future<Map<String, dynamic>> _exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Token exchange failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Token exchange error: $e');
    }
  }

  /// Fetch athlete profile from Strava
  /// Returns: name, age, weight, height, gender, profile photo
  Future<Map<String, dynamic>> fetchAthleteProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(_athleteUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final athlete = jsonDecode(response.body) as Map<String, dynamic>;

        // Extract relevant profile data
        return {
          'strava_athlete_id': athlete['id'],
          'first_name': athlete['firstname'],
          'last_name': athlete['lastname'],
          'profile_photo': athlete['profile_medium'] ?? athlete['profile'],
          'sex': athlete['sex'], // 'M' or 'F'
          'weight': athlete['weight'], // kg (if shared)
          'created_at': athlete['created_at'],
          'city': athlete['city'],
          'state': athlete['state'],
          'country': athlete['country'],
        };
      } else {
        throw Exception('Failed to fetch athlete profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Athlete profile fetch error: $e');
    }
  }

  /// Fetch ALL athlete activities (paginated)
  /// Fetches up to 1000 activities (Strava API limit per request: 200)
  Future<List<Map<String, dynamic>>> fetchAllActivities(
    String accessToken, {
    int maxActivities = 1000,
  }) async {
    final allActivities = <Map<String, dynamic>>[];
    int page = 1;
    const perPage = 200; // Max allowed by Strava

    try {
      while (allActivities.length < maxActivities) {
        final response = await http.get(
          Uri.parse(
            '$_activitiesUrl?page=$page&per_page=$perPage',
          ),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          final activities = jsonDecode(response.body) as List;

          if (activities.isEmpty) {
            break; // No more activities
          }

          allActivities.addAll(
            activities.map((a) => a as Map<String, dynamic>).toList(),
          );

          page++;

          // Respect Strava rate limits (100 requests per 15 minutes)
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          throw Exception('Failed to fetch activities: ${response.body}');
        }
      }

      return allActivities;
    } catch (e) {
      throw Exception('Activities fetch error: $e');
    }
  }

  /// Calculate Personal Bests from activities
  /// Returns: {5K: seconds, 10K: seconds, HalfMarathon: seconds, Marathon: seconds}
  Map<String, int?> calculatePersonalBests(
      List<Map<String, dynamic>> activities) {
    // Filter running activities only
    final runs = activities.where((a) => a['type'] == 'Run').toList();

    int? pb5k;
    int? pb10k;
    int? pbHalf;
    int? pbMarathon;

    for (final run in runs) {
      final distance = (run['distance'] as num?)?.toDouble() ?? 0.0;
      final movingTime = run['moving_time'] as int?;

      if (movingTime == null || movingTime == 0) continue;

      // 5K: 4.8 - 5.2 km
      if (distance >= 4800 && distance <= 5200) {
        if (pb5k == null || movingTime < pb5k) {
          pb5k = movingTime;
        }
      }

      // 10K: 9.8 - 10.2 km
      if (distance >= 9800 && distance <= 10200) {
        if (pb10k == null || movingTime < pb10k) {
          pb10k = movingTime;
        }
      }

      // Half Marathon: 20 - 22 km
      if (distance >= 20000 && distance <= 22000) {
        if (pbHalf == null || movingTime < pbHalf) {
          pbHalf = movingTime;
        }
      }

      // Marathon: 42 - 43 km
      if (distance >= 42000 && distance <= 43000) {
        if (pbMarathon == null || movingTime < pbMarathon) {
          pbMarathon = movingTime;
        }
      }
    }

    return {
      '5K': pb5k,
      '10K': pb10k,
      'HalfMarathon': pbHalf,
      'Marathon': pbMarathon,
    };
  }

  /// Calculate total mileage from activities
  /// Returns: total distance in kilometers
  double calculateTotalMileage(List<Map<String, dynamic>> activities) {
    final runs = activities.where((a) => a['type'] == 'Run');

    double totalMeters = 0.0;
    for (final run in runs) {
      final distance = (run['distance'] as num?)?.toDouble() ?? 0.0;
      totalMeters += distance;
    }

    return totalMeters / 1000; // Convert to km
  }

  /// Calculate activity statistics
  Map<String, dynamic> calculateActivityStats(
      List<Map<String, dynamic>> activities) {
    final runs = activities.where((a) => a['type'] == 'Run').toList();

    int totalRuns = runs.length;
    double totalDistance = calculateTotalMileage(activities);

    // Calculate total time
    int totalTime = 0;
    for (final run in runs) {
      totalTime += (run['moving_time'] as int?) ?? 0;
    }

    // Calculate average pace (min/km)
    double avgPace = totalDistance > 0 ? (totalTime / 60) / totalDistance : 0.0;

    // Find longest run
    double longestRun = 0.0;
    for (final run in runs) {
      final distance = ((run['distance'] as num?)?.toDouble() ?? 0.0) / 1000;
      if (distance > longestRun) {
        longestRun = distance;
      }
    }

    return {
      'total_runs': totalRuns,
      'total_distance_km': totalDistance,
      'total_time_hours': totalTime / 3600,
      'avg_pace_min_per_km': avgPace,
      'longest_run_km': longestRun,
    };
  }

  /// Store Strava profile and stats in Supabase
  Future<void> storeStravaProfile({
    required String userId,
    required Map<String, dynamic> athleteData,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    try {
      // Fetch complete profile
      final profile = await fetchAthleteProfile(accessToken);

      // Store in profiles table
      await _supabase.from('profiles').upsert({
        'id': userId,
        'strava_athlete_id': profile['strava_athlete_id'],
        'first_name': profile['first_name'],
        'last_name': profile['last_name'],
        'profile_photo_url': profile['profile_photo'],
        'gender': profile['sex'],
        'weight': profile['weight'],
        'strava_access_token': accessToken,
        'strava_refresh_token': refreshToken,
        'strava_token_expires_at': expiresAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to store Strava profile: $e');
    }
  }

  /// Start background sync of activities and stats
  /// This runs asynchronously and updates the database as it fetches data
  Future<void> startBackgroundSync(String userId) async {
    // Run in background (don't await)
    _performBackgroundSync(userId).then((_) {
      debugPrint('✅ Background sync completed for user $userId');
    }).catchError((e) {
      debugPrint('❌ Background sync failed: $e');
    });
  }

  Future<void> _performBackgroundSync(String userId) async {
    try {
      // 1. Get access token
      final profile = await _supabase
          .from('profiles')
          .select('strava_access_token')
          .eq('id', userId)
          .single();

      final accessToken = profile['strava_access_token'] as String;

      // 2. Fetch all activities (may take time)
      debugPrint('📥 Fetching activities for user $userId...');
      final activities = await fetchAllActivities(accessToken);
      debugPrint('✅ Fetched ${activities.length} activities');

      // 3. Calculate stats
      final pbs = calculatePersonalBests(activities);
      final stats = calculateActivityStats(activities);

      // 4. Update database
      await _supabase.from('profiles').update({
        'pb_5k': pbs['5K'],
        'pb_10k': pbs['10K'],
        'pb_half_marathon': pbs['HalfMarathon'],
        'pb_marathon': pbs['Marathon'],
        'total_runs': stats['total_runs'],
        'total_distance_km': stats['total_distance_km'],
        'total_time_hours': stats['total_time_hours'],
        'avg_pace_min_per_km': stats['avg_pace_min_per_km'],
        'longest_run_km': stats['longest_run_km'],
        'last_strava_sync': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      debugPrint('✅ Stats updated for user $userId');

      // 5. Store individual activities (optional, for detailed analysis)
      await _storeActivities(userId, activities);
    } catch (e) {
      debugPrint('❌ Background sync error: $e');
      rethrow;
    }
  }

  /// Store individual activities in database
  Future<void> _storeActivities(
    String userId,
    List<Map<String, dynamic>> activities,
  ) async {
    try {
      // Only store running activities
      final runs = activities.where((a) => a['type'] == 'Run').toList();

      // Batch insert (Supabase supports batch operations)
      final activitiesToInsert = runs.map((run) {
        return {
          'user_id': userId,
          'strava_activity_id': run['id'],
          'name': run['name'],
          'distance_meters': run['distance'],
          'moving_time_seconds': run['moving_time'],
          'elapsed_time_seconds': run['elapsed_time'],
          'total_elevation_gain': run['total_elevation_gain'],
          'activity_type': run['type'],
          'start_date': run['start_date'],
          'average_speed': run['average_speed'],
          'max_speed': run['max_speed'],
          'average_heartrate': run['average_heartrate'],
          'max_heartrate': run['max_heartrate'],
          'average_cadence': run['average_cadence'],
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      // Insert in batches of 100
      for (int i = 0; i < activitiesToInsert.length; i += 100) {
        final batch = activitiesToInsert.skip(i).take(100).toList();
        await _supabase.from('strava_activities').upsert(
              batch,
              onConflict: 'strava_activity_id',
            );
      }

      debugPrint('✅ Stored ${runs.length} activities');
    } catch (e) {
      debugPrint('❌ Failed to store activities: $e');
    }
  }

  /// Format time duration (seconds to HH:MM:SS or MM:SS)
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// Format pace (seconds per km to min:sec/km)
  static String formatPace(double secondsPerKm) {
    if (secondsPerKm.isInfinite || secondsPerKm.isNaN) {
      return '-:--';
    }

    final minutes = secondsPerKm ~/ 60;
    final seconds = (secondsPerKm % 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
