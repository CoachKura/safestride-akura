// GPS Data Fetcher - Universal Interface for Garmin, Coros, Strava
// Fetches running data from multiple GPS watch platforms
//
// Supported Platforms:
// - Garmin Connect API
// - Coros Training Hub API
// - Strava API v3
//
// Data Standardization:
// All data is normalized to a common format compatible with AISRI system

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

// Platform enum
enum GPSPlatform {
  garmin,
  coros,
  strava,
}

// Standardized GPS activity data - COMPLETE VERSION
class GPSActivity {
  final String id;
  final GPSPlatform platform;
  final DateTime startTime;
  final int durationSeconds;
  final double distanceMeters;
  final String? activityType;

  // Speed and Pace
  final double? avgPace; // min/km
  final double? avgSpeed; // km/h
  final double? maxSpeed; // km/h

  // Cadence
  final double? avgCadence; // steps per minute (FULL, not half)
  final double? maxCadence; // steps per minute

  // Heart Rate
  final double? avgHeartRate; // bpm
  final double? maxHeartRate; // bpm

  // Elevation
  final double? elevationGain; // meters
  final double? elevationLoss; // meters
  final double? maxElevation; // meters
  final double? minElevation; // meters

  // Advanced Biomechanics
  final double? avgGroundContactTime; // milliseconds
  final double? avgVerticalOscillation; // centimeters
  final double? avgStrideLength; // meters
  final double? avgVerticalRatio; // percentage

  // Training Effect
  final double? trainingLoad;
  final double? aerobicEffect;
  final double? anaerobicEffect;
  final double? sufferScore; // Strava-specific

  // Energy
  final int? calories;
  final double? avgWatts; // Power
  final double? maxWatts;
  final double? kilojoules;

  // Heart Rate Zones (time in seconds)
  final int? hrZone1Seconds; // Recovery 50-60%
  final int? hrZone2Seconds; // Aerobic 60-70%
  final int? hrZone3Seconds; // Tempo 70-80%
  final int? hrZone4Seconds; // Threshold 80-90%
  final int? hrZone5Seconds; // Anaerobic 90-100%

  // Additional Metrics
  final int? movingTimeSeconds;
  final int? elapsedTimeSeconds;
  final String? athleteId;
  final Map<String, dynamic>? rawData; // Complete original data

  GPSActivity({
    required this.id,
    required this.platform,
    required this.startTime,
    required this.durationSeconds,
    required this.distanceMeters,
    this.activityType,
    this.avgPace,
    this.avgSpeed,
    this.maxSpeed,
    this.avgCadence,
    this.maxCadence,
    this.avgHeartRate,
    this.maxHeartRate,
    this.elevationGain,
    this.elevationLoss,
    this.maxElevation,
    this.minElevation,
    this.avgGroundContactTime,
    this.avgVerticalOscillation,
    this.avgStrideLength,
    this.avgVerticalRatio,
    this.trainingLoad,
    this.aerobicEffect,
    this.anaerobicEffect,
    this.sufferScore,
    this.calories,
    this.avgWatts,
    this.maxWatts,
    this.kilojoules,
    this.hrZone1Seconds,
    this.hrZone2Seconds,
    this.hrZone3Seconds,
    this.hrZone4Seconds,
    this.hrZone5Seconds,
    this.movingTimeSeconds,
    this.elapsedTimeSeconds,
    this.athleteId,
    this.rawData,
  });

  // Convert to AISRI-compatible format
  Map<String, dynamic> toAISRIFormat() {
    return {
      'id': id,
      'platform': platform.name,
      'start_time': startTime.toIso8601String(),
      'duration': durationSeconds,
      'distance': distanceMeters / 1000, // km
      'average_cadence': avgCadence,
      'average_heart_rate': avgHeartRate,
      'average_pace': avgPace,
      'elevation_gain': elevationGain,
      'ground_contact_time': avgGroundContactTime,
      'vertical_oscillation': avgVerticalOscillation,
      'stride_length': avgStrideLength,
      'activity_type': activityType,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform.name,
      'start_time': startTime.toIso8601String(),
      'duration_seconds': durationSeconds,
      'distance_meters': distanceMeters,
      'avg_cadence': avgCadence,
      'avg_heart_rate': avgHeartRate,
      'avg_pace': avgPace,
      'elevation_gain': elevationGain,
      'avg_ground_contact_time': avgGroundContactTime,
      'avg_vertical_oscillation': avgVerticalOscillation,
      'avg_stride_length': avgStrideLength,
      'activity_type': activityType,
      'raw_data': rawData,
    };
  }

  factory GPSActivity.fromJson(Map<String, dynamic> json) {
    return GPSActivity(
      id: json['id'],
      platform:
          GPSPlatform.values.firstWhere((e) => e.name == json['platform']),
      startTime: DateTime.parse(json['start_time']),
      durationSeconds: json['duration_seconds'],
      distanceMeters: json['distance_meters'],
      avgCadence: json['avg_cadence'],
      avgHeartRate: json['avg_heart_rate'],
      avgPace: json['avg_pace'],
      elevationGain: json['elevation_gain'],
      avgGroundContactTime: json['avg_ground_contact_time'],
      avgVerticalOscillation: json['avg_vertical_oscillation'],
      avgStrideLength: json['avg_stride_length'],
      activityType: json['activity_type'],
      rawData: json['raw_data'],
    );
  }
}

// Main GPS Data Fetcher Service
class GPSDataFetcher {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== PUBLIC API ====================

  /// Fetch activities from all connected platforms
  Future<List<GPSActivity>> fetchAllActivities({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final activities = <GPSActivity>[];

    // Get user's connected platforms
    final connections = await _getConnectedPlatforms();

    for (var platform in connections.keys) {
      final accessToken = connections[platform];
      if (accessToken != null) {
        try {
          final platformActivities = await _fetchFromPlatform(
            platform: platform,
            accessToken: accessToken,
            startDate: startDate,
            endDate: endDate,
            limit: limit,
          );
          activities.addAll(platformActivities);
        } catch (e) {
          developer.log('Error fetching from $platform: $e');
        }
      }
    }

    // Sort by date (newest first)
    activities.sort((a, b) => b.startTime.compareTo(a.startTime));

    return activities;
  }

  /// Fetch activities from specific platform
  Future<List<GPSActivity>> fetchFromPlatform({
    required GPSPlatform platform,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final accessToken = await _getAccessToken(platform);
    if (accessToken == null) {
      throw Exception('Not connected to ${platform.name}');
    }

    return _fetchFromPlatform(
      platform: platform,
      accessToken: accessToken,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Check connection status for all platforms
  Future<Map<GPSPlatform, bool>> checkConnectionStatus() async {
    final connections = await _getConnectedPlatforms();
    return {
      GPSPlatform.garmin: connections.containsKey(GPSPlatform.garmin),
      GPSPlatform.coros: connections.containsKey(GPSPlatform.coros),
      GPSPlatform.strava: connections.containsKey(GPSPlatform.strava),
    };
  }

  // ==================== PLATFORM-SPECIFIC FETCHERS ====================

  Future<List<GPSActivity>> _fetchFromPlatform({
    required GPSPlatform platform,
    required String accessToken,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    switch (platform) {
      case GPSPlatform.garmin:
        return _fetchGarminActivities(accessToken, startDate, endDate, limit);
      case GPSPlatform.coros:
        return _fetchCorosActivities(accessToken, startDate, endDate, limit);
      case GPSPlatform.strava:
        return _fetchStravaActivities(accessToken, startDate, endDate, limit);
    }
  }

  // ==================== GARMIN CONNECT API ====================

  Future<List<GPSActivity>> _fetchGarminActivities(
    String accessToken,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  ) async {
    // Garmin Connect API endpoint
    // Documentation: https://developer.garmin.com/gc-developer-program/overview/

    final queryParams = <String, String>{
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (limit != null) 'limit': limit.toString(),
    };

    try {
      final response = await http.get(
        Uri.parse('https://apis.garmin.com/wellness-api/rest/activities')
            .replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseGarminActivities(data);
      } else {
        throw Exception('Garmin API error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching Garmin activities: $e');
      return [];
    }
  }

  List<GPSActivity> _parseGarminActivities(dynamic data) {
    final activities = <GPSActivity>[];

    if (data is List) {
      for (var activity in data) {
        if (activity['activityType'] == 'RUNNING' ||
            activity['activityType'] == 'TRAIL_RUNNING') {
          activities.add(GPSActivity(
            id: activity['activityId'].toString(),
            platform: GPSPlatform.garmin,
            startTime: DateTime.parse(activity['startTimeGMT']),
            durationSeconds: activity['duration'] as int,
            distanceMeters: (activity['distance'] as num).toDouble(),
            avgCadence: activity['averageRunCadence']?.toDouble(),
            avgHeartRate: activity['averageHR']?.toDouble(),
            avgPace: activity['averagePace']?.toDouble(),
            elevationGain: activity['elevationGain']?.toDouble(),
            avgGroundContactTime: activity['avgGroundContactTime']?.toDouble(),
            avgVerticalOscillation:
                activity['avgVerticalOscillation']?.toDouble(),
            avgStrideLength: activity['avgStrideLength']?.toDouble(),
            activityType: activity['activityType'],
            rawData: activity,
          ));
        }
      }
    }

    return activities;
  }

  // ==================== COROS API ====================

  Future<List<GPSActivity>> _fetchCorosActivities(
    String accessToken,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  ) async {
    // Coros Training Hub API
    // Documentation: https://open.coros.com/

    final queryParams = <String, String>{
      if (startDate != null)
        'start_date': (startDate.millisecondsSinceEpoch ~/ 1000).toString(),
      if (endDate != null)
        'end_date': (endDate.millisecondsSinceEpoch ~/ 1000).toString(),
      if (limit != null) 'limit': limit.toString(),
    };

    try {
      final response = await http.get(
        Uri.parse('https://open.coros.com/oauth2/v2/sport/list')
            .replace(queryParameters: queryParams),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseCorosActivities(data);
      } else {
        throw Exception('Coros API error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching Coros activities: $e');
      return [];
    }
  }

  List<GPSActivity> _parseCorosActivities(dynamic data) {
    final activities = <GPSActivity>[];

    if (data['data'] != null && data['data']['dataList'] is List) {
      for (var activity in data['data']['dataList']) {
        if (activity['mode'] == 11) {
          // 11 = Running
          activities.add(GPSActivity(
            id: activity['labelId'].toString(),
            platform: GPSPlatform.coros,
            startTime: DateTime.fromMillisecondsSinceEpoch(
                activity['startTime'] * 1000),
            durationSeconds: activity['duration'] as int,
            distanceMeters: (activity['distance'] as num).toDouble(),
            avgCadence: activity['avgCadence']?.toDouble(),
            avgHeartRate: activity['avgHeartRate']?.toDouble(),
            avgPace: activity['avgPace']?.toDouble(),
            elevationGain: activity['elevationGain']?.toDouble(),
            activityType: 'running',
            rawData: activity,
          ));
        }
      }
    }

    return activities;
  }

  // ==================== STRAVA API ====================

  Future<List<GPSActivity>> _fetchStravaActivities(
    String accessToken,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  ) async {
    // Strava API v3 - Fetch ALL activities with pagination
    // Documentation: https://developers.strava.com/docs/reference/

    developer.log('🔄 Fetching ALL Strava activities from day 1...');

    final allActivities = <GPSActivity>[];
    int page = 1;
    const perPage = 200; // Strava API max per page
    bool hasMoreActivities = true;

    try {
      while (hasMoreActivities) {
        final queryParams = <String, String>{
          'page': page.toString(),
          'per_page': perPage.toString(),
        };

        // Add date filters if provided
        if (startDate != null) {
          queryParams['after'] =
              (startDate.millisecondsSinceEpoch ~/ 1000).toString();
        }
        if (endDate != null) {
          queryParams['before'] =
              (endDate.millisecondsSinceEpoch ~/ 1000).toString();
        }

        developer.log(
            '   Fetching page $page (${allActivities.length} activities so far)...');

        final response = await http.get(
          Uri.parse('https://www.strava.com/api/v3/athlete/activities')
              .replace(queryParameters: queryParams),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data is List && data.isNotEmpty) {
            final pageActivities = _parseStravaActivities(data);
            allActivities.addAll(pageActivities);

            developer.log(
                '   ✅ Page $page: Found ${pageActivities.length} activities');

            // Check if we've hit the user's limit
            if (limit != null && allActivities.length >= limit) {
              developer.log('   🛑 Reached limit of $limit activities');
              hasMoreActivities = false;
            } else if (data.length < perPage) {
              // Less than perPage means this is the last page
              developer.log('   🏁 Reached last page');
              hasMoreActivities = false;
            } else {
              page++;
            }
          } else {
            // Empty page means no more activities
            developer.log('   🏁 No more activities found');
            hasMoreActivities = false;
          }
        } else if (response.statusCode == 429) {
          // Rate limit exceeded
          developer.log('   ⚠️ Rate limit exceeded, waiting 60 seconds...');
          await Future.delayed(const Duration(seconds: 60));
          // Retry the same page
        } else {
          throw Exception('Strava API error: ${response.statusCode}');
        }
      }

      developer.log('✅ Total activities fetched: ${allActivities.length}');
      return limit != null ? allActivities.take(limit).toList() : allActivities;
    } catch (e) {
      developer.log('❌ Error fetching Strava activities: $e');
      return allActivities; // Return what we have so far
    }
  }

  List<GPSActivity> _parseStravaActivities(dynamic data) {
    final activities = <GPSActivity>[];

    if (data is List) {
      for (var activity in data) {
        if (activity['type'] == 'Run' || activity['type'] == 'TrailRun') {
          // Calculate metrics
          final distance = (activity['distance'] as num?)?.toDouble() ?? 0.0;
          final distanceKm = distance / 1000; // km
          final movingTime = (activity['moving_time'] as int?) ?? 0;
          final duration = movingTime / 60; // minutes
          final pace = distanceKm > 0 ? duration / distanceKm : null;

          // Calculate stride length from cadence and speed if available
          // Stride Length (m) = (Speed m/s) / (Cadence steps/s)
          double? strideLength;
          final avgSpeed = (activity['average_speed'] as num?)?.toDouble();
          final avgCadence = (activity['average_cadence'] as num?)?.toDouble();
          if (avgSpeed != null && avgCadence != null && avgCadence > 0) {
            // avgSpeed is in m/s, avgCadence is steps/min (reported as half by Strava)
            final fullCadence = avgCadence * 2; // Convert to full cadence
            final cadencePerSecond = fullCadence / 60; // steps per second
            strideLength = avgSpeed / cadencePerSecond; // meters per step
          }

          activities.add(GPSActivity(
            id: activity['id'].toString(),
            platform: GPSPlatform.strava,
            startTime: DateTime.parse(activity['start_date']),
            durationSeconds: movingTime,
            distanceMeters: distance,
            activityType: activity['type'],

            // Speed and Pace
            avgPace: pace,
            avgSpeed: avgSpeed != null ? avgSpeed * 3.6 : null, // m/s to km/h
            maxSpeed: (activity['max_speed'] as num?)?.toDouble() != null
                ? (activity['max_speed'] as num).toDouble() * 3.6 // m/s to km/h
                : null,

            // Cadence (Strava reports HALF cadence - multiply by 2)
            avgCadence: avgCadence != null ? avgCadence * 2 : null,
            maxCadence: (activity['max_cadence'] as num?)?.toDouble() != null
                ? (activity['max_cadence'] as num).toDouble() * 2
                : null,

            // Heart Rate
            avgHeartRate: (activity['average_heartrate'] as num?)?.toDouble(),
            maxHeartRate: (activity['max_heartrate'] as num?)?.toDouble(),

            // Elevation
            elevationGain:
                (activity['total_elevation_gain'] as num?)?.toDouble(),
            elevationLoss:
                (activity['total_elevation_loss'] as num?)?.toDouble(),
            maxElevation: (activity['elev_high'] as num?)?.toDouble(),
            minElevation: (activity['elev_low'] as num?)?.toDouble(),

            // Biomechanics (calculated)
            avgStrideLength: strideLength,

            // Training Effect (Strava-specific)
            sufferScore: (activity['suffer_score'] as num?)?.toDouble(),

            // Energy
            calories: activity['calories'] as int?,
            avgWatts: (activity['average_watts'] as num?)?.toDouble(),
            maxWatts: (activity['max_watts'] as num?)?.toDouble(),
            kilojoules: (activity['kilojoules'] as num?)?.toDouble(),

            // Time metrics
            movingTimeSeconds: movingTime,
            elapsedTimeSeconds: activity['elapsed_time'] as int?,

            // Athlete info
            athleteId: activity['athlete']?['id']?.toString(),

            // Store complete raw data for future analysis
            rawData: activity,
          ));
        }
      }
    }

    return activities;
  }

  // ==================== TOKEN MANAGEMENT ====================

  /// Get connected platforms and their access tokens
  Future<Map<GPSPlatform, String>> _getConnectedPlatforms() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('gps_connections')
          .select()
          .eq('user_id', userId);

      final connections = <GPSPlatform, String>{};

      for (var conn in response) {
        final platformName = conn['platform'] as String;
        final accessToken = conn['access_token'] as String?;

        if (accessToken != null) {
          try {
            final platform = GPSPlatform.values.firstWhere(
              (e) => e.name == platformName,
            );
            connections[platform] = accessToken;
          } catch (e) {
            developer.log('Unknown platform: $platformName');
          }
        }
      }

      return connections;
    } catch (e) {
      developer.log('Error getting connected platforms: $e');
      return {};
    }
  }

  /// Get access token for specific platform
  Future<String?> _getAccessToken(GPSPlatform platform) async {
    final connections = await _getConnectedPlatforms();
    var token = connections[platform];

    // Fallback: if Strava isn't cached in gps_connections yet, pull from profiles
    if (token == null && platform == GPSPlatform.strava) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select(
              'strava_access_token, strava_refresh_token, strava_expires_at')
          .eq('id', userId)
          .maybeSingle();

      final profileToken = profile?['strava_access_token'] as String?;
      if (profileToken != null) {
        final expiresAtRaw = profile?['strava_expires_at'] as String?;
        final expiresAt =
            expiresAtRaw != null ? DateTime.tryParse(expiresAtRaw) : null;

        // Cache into gps_connections so downstream calls work without reconnecting
        await storeAccessToken(
          platform: platform,
          accessToken: profileToken,
          refreshToken: profile?['strava_refresh_token'] as String?,
          expiresAt: expiresAt,
        );

        token = profileToken;
      }
    }

    return token;
  }

  /// Store access token for platform
  Future<void> storeAccessToken({
    required GPSPlatform platform,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase.from('gps_connections').upsert({
      'user_id': userId,
      'platform': platform.name,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt?.toIso8601String(),
      'connected_at': DateTime.now().toIso8601String(),
    });
  }

  /// Disconnect from platform
  Future<void> disconnectPlatform(GPSPlatform platform) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase
        .from('gps_connections')
        .delete()
        .eq('user_id', userId)
        .eq('platform', platform.name);
  }

  /// Save activities to database with ALL available metrics
  /// Organizes data by CALENDAR DATE for easy querying
  /// Returns map with: 'savedCount', 'totalActivities', 'dateRange', 'activitiesByDate'
  Future<Map<String, dynamic>> saveActivitiesToDatabase(
      List<GPSActivity> activities) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    int savedCount = 0;
    final activitiesByDate = <DateTime, List<GPSActivity>>{};

    developer.log('\n📅 ORGANIZING ACTIVITIES BY CALENDAR DATE...');

    // Group activities by calendar date BEFORE saving
    for (var activity in activities) {
      final dateOnly = DateTime(activity.startTime.year,
          activity.startTime.month, activity.startTime.day);
      activitiesByDate.putIfAbsent(dateOnly, () => []).add(activity);
    }

    developer.log(
        '📊 Found ${activitiesByDate.length} unique dates with activities');
    developer.log(
        '   Date range: ${activities.last.startTime.toString().split(' ')[0]} to ${activities.first.startTime.toString().split(' ')[0]}\n');

    // Save each activity with calendar date organization
    for (var activity in activities) {
      try {
        // Check if activity already exists
        final existing = await _supabase
            .from('gps_activities')
            .select('id')
            .eq('user_id', userId)
            .eq('platform', activity.platform.name)
            .eq('platform_activity_id', activity.id)
            .maybeSingle();

        if (existing == null) {
          // Insert new activity with ALL fields
          await _supabase.from('gps_activities').insert({
            'user_id': userId,
            'athlete_id': activity.athleteId ?? userId,
            'platform': activity.platform.name,
            'platform_activity_id': activity.id,
            'activity_type': activity.activityType ?? 'Run',
            'start_time': activity.startTime.toIso8601String(),

            // Duration and distance
            'duration_seconds': activity.durationSeconds,
            'moving_time_seconds': activity.movingTimeSeconds,
            'elapsed_time_seconds': activity.elapsedTimeSeconds,
            'distance_meters': activity.distanceMeters,

            // Speed and Pace
            'avg_pace': activity.avgPace,
            'avg_speed': activity.avgSpeed,
            'max_speed': activity.maxSpeed,

            // Cadence
            'avg_cadence': activity.avgCadence,
            'max_cadence': activity.maxCadence,

            // Heart Rate
            'avg_heart_rate': activity.avgHeartRate,
            'max_heart_rate': activity.maxHeartRate,

            // Elevation
            'elevation_gain': activity.elevationGain,
            'elevation_loss': activity.elevationLoss,
            'max_elevation': activity.maxElevation,
            'min_elevation': activity.minElevation,

            // Advanced Biomechanics
            'avg_ground_contact_time': activity.avgGroundContactTime,
            'avg_vertical_oscillation': activity.avgVerticalOscillation,
            'avg_stride_length': activity.avgStrideLength,
            'avg_vertical_ratio': activity.avgVerticalRatio,

            // Training Effect
            'training_load': activity.trainingLoad ?? activity.sufferScore,
            'aerobic_training_effect': activity.aerobicEffect,
            'anaerobic_training_effect': activity.anaerobicEffect,

            // Energy and Power
            'calories': activity.calories,

            // Heart Rate Zones
            'hr_zone_1_seconds': activity.hrZone1Seconds,
            'hr_zone_2_seconds': activity.hrZone2Seconds,
            'hr_zone_3_seconds': activity.hrZone3Seconds,
            'hr_zone_4_seconds': activity.hrZone4Seconds,
            'hr_zone_5_seconds': activity.hrZone5Seconds,

            // Complete raw data for future analysis
            'raw_data': activity.rawData,
            'synced_at': DateTime.now().toIso8601String(),
          });
          savedCount++;
        }
      } catch (e) {
        developer.log('Error saving activity ${activity.id}: $e');
      }
    }

    developer.log('\n✅ CALENDAR DATE STORAGE COMPLETE:');
    developer.log('   💾 Saved $savedCount NEW activities');
    developer.log(
        '   📅 Organized across ${activitiesByDate.length} calendar dates');
    developer.log('   📊 Total activities processed: ${activities.length}');

    // Display calendar summary
    developer.log('\n📅 ACTIVITIES BY CALENDAR DATE:');
    final sortedDates = activitiesByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    for (var date in sortedDates.take(10)) {
      final count = activitiesByDate[date]!.length;
      final totalKm = activitiesByDate[date]!
          .fold<double>(0, (sum, a) => sum + a.distanceMeters / 1000);
      developer.log(
          '   ${date.toString().split(' ')[0]}: $count run(s), ${totalKm.toStringAsFixed(1)} km');
    }
    if (sortedDates.length > 10) {
      developer.log('   ... and ${sortedDates.length - 10} more dates');
    }

    return {
      'savedCount': savedCount,
      'totalActivities': activities.length,
      'uniqueDates': activitiesByDate.length,
      'dateRange': {
        'oldest': activities.last.startTime,
        'newest': activities.first.startTime,
      },
      'activitiesByDate': activitiesByDate,
    };
  }

  /// Get activities for a specific date range (calendar view)
  /// Returns activities grouped by date
  Future<Map<DateTime, List<GPSActivity>>> getActivitiesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    GPSPlatform? platform,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      // Build query with all filters
      final baseQuery = _supabase
          .from('gps_activities')
          .select()
          .eq('user_id', userId)
          .gte('start_time', startDate.toIso8601String())
          .lte('start_time', endDate.toIso8601String());

      // Add platform filter if specified, then order
      final response = platform != null
          ? await baseQuery
              .eq('platform', platform.name)
              .order('start_time', ascending: false)
          : await baseQuery.order('start_time', ascending: false);

      final activities = <GPSActivity>[];

      for (var row in response) {
        activities.add(GPSActivity(
          id: row['platform_activity_id'],
          platform:
              GPSPlatform.values.firstWhere((e) => e.name == row['platform']),
          startTime: DateTime.parse(row['start_time']),
          durationSeconds: row['duration_seconds'],
          distanceMeters: (row['distance_meters'] as num).toDouble(),
          activityType: row['activity_type'],
          avgPace: (row['avg_pace'] as num?)?.toDouble(),
          avgSpeed: (row['avg_speed'] as num?)?.toDouble(),
          maxSpeed: (row['max_speed'] as num?)?.toDouble(),
          avgCadence: (row['avg_cadence'] as num?)?.toDouble(),
          maxCadence: (row['max_cadence'] as num?)?.toDouble(),
          avgHeartRate: (row['avg_heart_rate'] as num?)?.toDouble(),
          maxHeartRate: (row['max_heart_rate'] as num?)?.toDouble(),
          elevationGain: (row['elevation_gain'] as num?)?.toDouble(),
          elevationLoss: (row['elevation_loss'] as num?)?.toDouble(),
          maxElevation: (row['max_elevation'] as num?)?.toDouble(),
          minElevation: (row['min_elevation'] as num?)?.toDouble(),
          avgStrideLength: (row['avg_stride_length'] as num?)?.toDouble(),
          calories: row['calories'] as int?,
          movingTimeSeconds: row['moving_time_seconds'] as int?,
          elapsedTimeSeconds: row['elapsed_time_seconds'] as int?,
          athleteId: row['athlete_id'],
          rawData: row['raw_data'],
        ));
      }

      // Group by date (calendar format)
      final grouped = <DateTime, List<GPSActivity>>{};
      for (var activity in activities) {
        final dateOnly = DateTime(activity.startTime.year,
            activity.startTime.month, activity.startTime.day);
        grouped.putIfAbsent(dateOnly, () => []).add(activity);
      }

      return grouped;
    } catch (e) {
      developer.log('Error fetching activities by date: $e');
      return {};
    }
  }

  /// Fetch activity with detailed time-series data (streams)
  Future<ActivityDetails> fetchActivityDetails({
    required String activityId,
    GPSPlatform platform = GPSPlatform.strava,
  }) async {
    final accessToken = await _getAccessToken(platform);
    if (accessToken == null) {
      throw Exception('Not connected to ${platform.name}');
    }

    switch (platform) {
      case GPSPlatform.strava:
        return _fetchStravaActivityDetails(activityId, accessToken);
      case GPSPlatform.garmin:
        return _fetchGarminActivityDetails(activityId, accessToken);
      case GPSPlatform.coros:
        return _fetchCorosActivityDetails(activityId, accessToken);
    }
  }

  /// Fetch Strava activity streams (time-series data)
  Future<ActivityDetails> _fetchStravaActivityDetails(
      String activityId, String accessToken) async {
    try {
      // Get activity summary
      final activityResponse = await http.get(
        Uri.parse('https://www.strava.com/api/v3/activities/$activityId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      // Get activity streams (time-series data)
      final streamsResponse = await http.get(
        Uri.parse('https://www.strava.com/api/v3/activities/$activityId/streams'
            '?keys=time,heartrate,altitude,velocity_smooth,cadence,distance,latlng'
            '&key_by_type=true'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (activityResponse.statusCode == 200) {
        final activity = jsonDecode(activityResponse.body);

        List<DataPoint> timeSeriesData = [];
        if (streamsResponse.statusCode == 200) {
          final streams = jsonDecode(streamsResponse.body);
          timeSeriesData = _parseStravaStreams(streams, activity['start_date']);
        }

        // Calculate pace from distance and time
        final distance = (activity['distance'] as num?)?.toDouble() ?? 0;
        final movingTime = (activity['moving_time'] as int?) ?? 0;
        double? avgPace;
        if (distance > 0 && movingTime > 0) {
          avgPace = (movingTime / 60) / (distance / 1000); // min/kmw
        }

        return ActivityDetails(
          id: activityId,
          platform: GPSPlatform.strava,
          startTime: DateTime.parse(activity['start_date']),
          durationSeconds: movingTime,
          distanceMeters: distance,
          avgHeartRate: (activity['average_heartrate'] as num?)?.toDouble(),
          maxHeartRate: (activity['max_heartrate'] as num?)?.toDouble(),
          avgPace: avgPace,
          elevationGain: (activity['total_elevation_gain'] as num?)?.toDouble(),
          calories: (activity['calories'] as num?)?.toDouble(),
          avgCadence: (activity['average_cadence'] as num?)?.toDouble(),
          maxCadence: (activity['max_cadence'] as num?)?.toDouble(),
          avgSpeed: (activity['average_speed'] as num?)?.toDouble(),
          maxSpeed: (activity['max_speed'] as num?)?.toDouble(),
          timeSeriesData: timeSeriesData,
          rawData: activity,
        );
      }

      throw Exception(
          'Failed to fetch Strava activity: ${activityResponse.statusCode}');
    } catch (e) {
      developer.log('Error fetching Strava activity details: $e');
      rethrow;
    }
  }

  /// Parse Strava streams into DataPoints
  List<DataPoint> _parseStravaStreams(
      Map<String, dynamic> streams, String startDateStr) {
    final timeData = streams['time']?['data'] as List?;
    final hrData = streams['heartrate']?['data'] as List?;
    final altitudeData = streams['altitude']?['data'] as List?;
    final velocityData = streams['velocity_smooth']?['data'] as List?;
    final cadenceData = streams['cadence']?['data'] as List?;
    final distanceData = streams['distance']?['data'] as List?;
    final latLngData = streams['latlng']?['data'] as List?;

    if (timeData == null || timeData.isEmpty) return [];

    final startTime = DateTime.parse(startDateStr);

    return List.generate(timeData.length, (i) {
      final speed = velocityData?[i]?.toDouble();
      double? pace;
      if (speed != null && speed > 0) {
        // Convert m/s to min/km
        pace = 1000 / (speed * 60);
      }

      double? latitude;
      double? longitude;
      if (latLngData != null && i < latLngData.length) {
        final point = latLngData[i];
        if (point is List && point.length >= 2) {
          final lat = point[0];
          final lng = point[1];
          if (lat is num) latitude = lat.toDouble();
          if (lng is num) longitude = lng.toDouble();
        }
      }

      return DataPoint(
        timestamp: startTime.add(Duration(seconds: timeData[i])),
        timeSeconds: timeData[i],
        heartRate: hrData?[i]?.toDouble(),
        elevation: altitudeData?[i]?.toDouble(),
        speed: speed,
        cadence: cadenceData?[i]?.toDouble(),
        pace: pace,
        distance: distanceData?[i]?.toDouble(),
        latitude: latitude,
        longitude: longitude,
      );
    });
  }

  /// Garmin activity details (placeholder)
  Future<ActivityDetails> _fetchGarminActivityDetails(
      String activityId, String accessToken) async {
    // Garmin API implementation would go here
    throw UnimplementedError('Garmin activity details not yet implemented');
  }

  /// Coros activity details (placeholder)
  Future<ActivityDetails> _fetchCorosActivityDetails(
      String activityId, String accessToken) async {
    // Coros API implementation would go here
    throw UnimplementedError('Coros activity details not yet implemented');
  }
}

// Time-series data point for activity charts
class DataPoint {
  final DateTime timestamp;
  final int timeSeconds;
  final double? heartRate;
  final double? pace;
  final double? elevation;
  final double? cadence;
  final double? speed;
  final double? distance;
  final double? latitude;
  final double? longitude;

  DataPoint({
    required this.timestamp,
    required this.timeSeconds,
    this.heartRate,
    this.pace,
    this.elevation,
    this.cadence,
    this.speed,
    this.distance,
    this.latitude,
    this.longitude,
  });
}

// Detailed activity data with time-series
class ActivityDetails {
  final String id;
  final GPSPlatform platform;
  final DateTime startTime;
  final int durationSeconds;
  final double distanceMeters;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final double? avgPace;
  final double? elevationGain;
  final double? calories;
  final double? avgCadence;
  final double? maxCadence;
  final double? avgSpeed;
  final double? maxSpeed;
  final List<DataPoint> timeSeriesData;
  final Map<String, dynamic>? rawData;

  ActivityDetails({
    required this.id,
    required this.platform,
    required this.startTime,
    required this.durationSeconds,
    required this.distanceMeters,
    this.avgHeartRate,
    this.maxHeartRate,
    this.avgPace,
    this.elevationGain,
    this.calories,
    this.avgCadence,
    this.maxCadence,
    this.avgSpeed,
    this.maxSpeed,
    this.timeSeriesData = const [],
    this.rawData,
  });

  String get durationDisplay {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get distanceDisplay {
    return (distanceMeters / 1000).toStringAsFixed(2);
  }

  String get paceDisplay {
    if (avgPace == null) return 'N/A';
    final minutes = avgPace!.floor();
    final seconds = ((avgPace! - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  double get bestPace {
    final paces = timeSeriesData
        .where((d) => d.pace != null && d.pace! > 0 && d.pace! < 30)
        .map((d) => d.pace!)
        .toList();
    if (paces.isEmpty) return avgPace ?? 0;
    return paces.reduce((a, b) => a < b ? a : b);
  }

  double get minElevation {
    final elevations = timeSeriesData
        .where((d) => d.elevation != null)
        .map((d) => d.elevation!)
        .toList();
    if (elevations.isEmpty) return 0;
    return elevations.reduce((a, b) => a < b ? a : b);
  }

  double get maxElevation {
    final elevations = timeSeriesData
        .where((d) => d.elevation != null)
        .map((d) => d.elevation!)
        .toList();
    if (elevations.isEmpty) return 0;
    return elevations.reduce((a, b) => a > b ? a : b);
  }
}

// V.O2 Data Adapter - Converts V.O2 dashboard data to AISRI format
class VO2DataAdapter {
  /// Convert V.O2 athlete data to AISRI-compatible format
  ///
  /// V.O2 Data Structure:
  /// - VDOT: Fitness level (20-85)
  /// - Weekly Mileage: km/week
  /// - Cadence: steps/min (from GPS watch)
  /// - Recent Race: race performance
  ///
  /// AISRI Mapping:
  /// - VDOT → Endurance Score
  /// - Cadence → Movement Efficiency
  /// - Weekly Mileage → Training Load
  static Map<String, dynamic> convertVO2ToAISRI({
    required double vdot,
    required double weeklyMileageKm,
    required double? cadence,
    String? recentRace,
    String? athleteGroup,
  }) {
    // Convert VDOT to AISRI Endurance Score (0-100)
    // VDOT ranges: 20 (beginner) to 85 (elite)
    // Map to 0-100 scale
    final enduranceScore = ((vdot - 20) / 65 * 100).clamp(0, 100).toInt();

    // Cadence assessment (optimal: 170-180 spm)
    int mobilityScore = 60; // default
    if (cadence != null) {
      if (cadence >= 170 && cadence <= 180) {
        mobilityScore = 85;
      } else if (cadence >= 160 && cadence < 170) {
        mobilityScore = 70;
      } else if (cadence < 160) {
        mobilityScore = 50;
      } else {
        mobilityScore = 75;
      }
    }

    // Weekly mileage assessment
    // <20km = Low, 20-40km = Moderate, 40-60km = High, >60km = Very High
    int strengthScore = 60; // default
    if (weeklyMileageKm < 20) {
      strengthScore = 50;
    } else if (weeklyMileageKm >= 20 && weeklyMileageKm < 40) {
      strengthScore = 65;
    } else if (weeklyMileageKm >= 40 && weeklyMileageKm < 60) {
      strengthScore = 75;
    } else {
      strengthScore = 80;
    }

    // Calculate overall AISRI score
    final aisriScore =
        ((enduranceScore + mobilityScore + strengthScore) / 3).round();

    return {
      'aisri_score': aisriScore,
      'endurance_score': enduranceScore,
      'mobility_score': mobilityScore,
      'strength_score': strengthScore,
      'balance_score': 60, // Default until assessed
      'flexibility_score': 60, // Default until assessed
      'power_score': 60, // Default until assessed
      'source': 'vo2',
      'vo2_data': {
        'vdot': vdot,
        'weekly_mileage_km': weeklyMileageKm,
        'cadence': cadence,
        'recent_race': recentRace,
        'athlete_group': athleteGroup,
      },
    };
  }

  /// Convert V.O2 workout history to GPSActivity format
  static GPSActivity convertVO2WorkoutToActivity({
    required String workoutId,
    required DateTime date,
    required double distanceKm,
    required int durationMinutes,
    double? cadence,
    double? heartRate,
  }) {
    final durationSeconds = durationMinutes * 60;
    final distanceMeters = distanceKm * 1000;
    final pace = durationMinutes / distanceKm; // min/km

    return GPSActivity(
      id: workoutId,
      platform: GPSPlatform.strava, // Default to Strava
      startTime: date,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
      avgCadence: cadence,
      avgHeartRate: heartRate,
      avgPace: pace,
      activityType: 'run',
      rawData: {
        'source': 'vo2',
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
      },
    );
  }
}
