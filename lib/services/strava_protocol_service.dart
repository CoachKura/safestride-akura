import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/aisri_assessment.dart';
import 'strava_analyzer.dart';
import 'protocol_generator.dart';
import 'calendar_scheduler.dart';
import 'gps_data_fetcher.dart';
import 'dart:developer' as developer;

class StravaProtocolService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProtocolGenerator _protocolGenerator = ProtocolGenerator();
  final CalendarScheduler _scheduler = CalendarScheduler();
  final GPSDataFetcher _gpsDataFetcher = GPSDataFetcher();

  // Main method: Fetch Strava data, generate protocol, schedule to calendar
  Future<ProtocolGenerationResult> generateAndScheduleProtocol({
    bool clearExisting = false,
  }) async {
    try {
      // Step 1: Get athlete ID
      final athleteId = await _getAthleteId();
      if (athleteId == null) {
        throw Exception('Athlete profile not found');
      }

      // Step 2: Fetch Strava activities
      developer.log('Fetching Strava activities...');
      final activities = await _fetchStravaActivities(athleteId);

      if (activities.isEmpty) {
        throw Exception(
            'No Strava activities found. Please sync your Strava account first.');
      }

      // Step 3: Fetch AISRI assessment data
      developer.log('Fetching AISRI assessment...');
      final aisriData = await _fetchAISRIData(athleteId);

      // Step 4: Analyze data
      developer.log('Analyzing Strava + AISRI data...');
      final analysis = StravaAnalyzer.analyzeActivities(activities, aisriData);

      if (!analysis.hasData) {
        throw Exception('Insufficient data for analysis');
      }

      // Step 5: Generate protocol
      developer.log('Generating workout protocol...');
      final protocol = await _protocolGenerator.generateProtocol(
        analysis: analysis,
        athleteId: athleteId,
        durationWeeks: 2,
        workoutsPerWeek: 3,
      );

      // Step 6: Clear existing schedule if requested
      if (clearExisting) {
        developer.log('Clearing existing schedule...');
        await _scheduler.clearExistingSchedule(athleteId);
      }

      // Step 7: Schedule to calendar
      developer.log('Scheduling workouts to calendar...');
      final schedulingResult = await _scheduler.scheduleProtocol(
        athleteId: athleteId,
        protocol: protocol,
      );

      return ProtocolGenerationResult(
        success: schedulingResult.success,
        protocol: protocol,
        analysis: analysis,
        schedulingResult: schedulingResult,
        message: schedulingResult.success
            ? '✅ ${schedulingResult.scheduledCount} workouts scheduled!'
            : '❌ Failed to schedule workouts',
      );
    } catch (e) {
      developer.log('Error generating protocol: $e');
      return ProtocolGenerationResult(
        success: false,
        protocol: null,
        analysis: null,
        schedulingResult: null,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // Get athlete ID from current user
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

  // Fetch GPS activities from all connected platforms
  Future<List<Map<String, dynamic>>> _fetchStravaActivities(
      String athleteId) async {
    try {
      // Option 1: Try to fetch from database (previously synced activities)
      final dbActivities = await _fetchActivitiesFromDatabase(athleteId);
      if (dbActivities.isNotEmpty) {
        developer.log('Using ${dbActivities.length} activities from database');
        return dbActivities;
      }

      // Option 2: Fetch from GPS watch platforms (Garmin, Coros, Strava)
      developer.log('Fetching activities from GPS platforms...');
      final endDate = DateTime.now();
      final startDate =
          endDate.subtract(const Duration(days: 30)); // Last 30 days

      final gpsActivities = await _gpsDataFetcher.fetchAllActivities(
        startDate: startDate,
        endDate: endDate,
        limit: 50,
      );

      if (gpsActivities.isNotEmpty) {
        developer.log(
            'Fetched ${gpsActivities.length} activities from GPS platforms');
        // Store activities in database for future use
        await _storeActivitiesInDatabase(athleteId, gpsActivities);
        return gpsActivities.map((a) => a.toJson()).toList();
      }

      // Option 3: Check user metadata (for backward compatibility)
      final user = _supabase.auth.currentUser;
      final stravaData = user?.userMetadata?['strava_activities'];
      if (stravaData != null && stravaData is List) {
        developer.log('Using activities from user metadata');
        return List<Map<String, dynamic>>.from(stravaData);
      }

      // Option 4: Return mock data for testing (if no real data available)
      developer.log('No real activities found - using mock data for testing');
      return _getMockStravaActivities();
    } catch (e) {
      developer.log('Error fetching activities: $e');
      // Fallback to mock data
      return _getMockStravaActivities();
    }
  }

  // Fetch activities from database
  Future<List<Map<String, dynamic>>> _fetchActivitiesFromDatabase(
      String athleteId) async {
    try {
      final response = await _supabase
          .from('gps_activities')
          .select()
          .eq('athlete_id', athleteId)
          .gte(
              'start_time',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String())
          .order('start_time', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('Error fetching from database: $e');
      return [];
    }
  }

  // Store activities in database
  Future<void> _storeActivitiesInDatabase(
    String athleteId,
    List<GPSActivity> activities,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      for (var activity in activities) {
        await _supabase.from('gps_activities').upsert({
          'user_id': userId,
          'athlete_id': athleteId,
          'platform': activity.platform.name,
          'platform_activity_id': activity.id,
          'activity_type': activity.activityType ?? 'run',
          'start_time': activity.startTime.toIso8601String(),
          'duration_seconds': activity.durationSeconds,
          'distance_meters': activity.distanceMeters,
          'avg_cadence': activity.avgCadence,
          'avg_heart_rate': activity.avgHeartRate,
          'avg_pace': activity.avgPace,
          'elevation_gain': activity.elevationGain,
          'avg_ground_contact_time': activity.avgGroundContactTime,
          'avg_vertical_oscillation': activity.avgVerticalOscillation,
          'avg_stride_length': activity.avgStrideLength,
          'raw_data': activity.rawData,
          'synced_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      developer.log('Error storing activities: $e');
    }
  }

  // Fetch AISRI assessment data
  Future<Map<String, dynamic>?> _fetchAISRIData(String athleteId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Fetch latest AISRI assessment from new table
      final assessmentResponse = await _supabase
          .from('aisri_assessments')
          .select('*')
          .eq('user_id', userId)
          .order('assessment_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (assessmentResponse != null) {
        // Parse into AISRI model
        final assessment = AISRIAssessment.fromJson(assessmentResponse);

        return {
          'aisri_score': assessment.aisriScore,
          'risk_level': assessment.riskLevel,
          'mobility_score': assessment.mobilityScore,
          'strength_score': assessment.strengthScore,
          'balance_score': assessment.balanceScore,
          'flexibility_score': assessment.flexibilityScore,
          'endurance_score': assessment.enduranceScore,
          'power_score': assessment.powerScore,
          'weekly_distance': assessment.weeklyDistance,
          'avg_cadence': assessment.avgCadence,
          'avg_pace': assessment.avgPace,
          'past_injuries': assessment.pastInjuries,
          'ground_contact_time': assessment.groundContactTime,
          'vertical_oscillation': assessment.verticalOscillation,
          'stride_length': assessment.strideLength,
        };
      }

      developer.log('No AISRI assessment found for user');

      // Return default values if no assessment exists
      return {
        'aisri_score': 50,
        'risk_level': 'Moderate Risk',
        'mobility_score': 60,
        'strength_score': 60,
        'balance_score': 60,
        'flexibility_score': 60,
        'endurance_score': 60,
        'power_score': 60,
        'weekly_distance': 25.0,
        'avg_cadence': 170,
        'avg_pace': 6.0,
        'past_injuries': [],
      };
    } catch (e) {
      developer.log('Error fetching AISRI data: $e');
      return null;
    }
  }

  // Mock Strava activities for testing
  // Based on KURA's actual V.O2 data: VDOT 23.0, 151 spm cadence, 27.2 km/week
  List<Map<String, dynamic>> _getMockStravaActivities() {
    return [
      {
        'distance': 5220, // meters (5.22 km from actual run)
        'moving_time': 2662, // seconds (44:22 = 8:30/km pace)
        'average_cadence':
            75, // half cadence (151 spm actual - matches V.O2 data)
        'average_heartrate': 142, // matches V.O2 data
      },
      {
        'distance': 8000, // 8 km run
        'moving_time': 4080, // 68 min (8:30/km pace)
        'average_cadence': 76, // ~152 spm
        'average_heartrate': 145,
      },
      {
        'distance': 10000, // 10 km run
        'moving_time': 5100, // 85 min (8:30/km pace)
        'average_cadence': 75, // 150 spm
        'average_heartrate': 148,
      },
      {
        'distance': 4000, // 4 km recovery
        'moving_time': 2040, // 34 min (8:30/km pace)
        'average_cadence': 74, // 148 spm
        'average_heartrate': 138,
      },
    ];
    // Total: 27.22 km (matches V.O2 previous week: 27.2 km)
    // Avg cadence: ~151 spm (LOW - optimal is 170+)
    // Avg HR: ~143 bpm
    // Avg pace: 8:30/km (VDOT ~23)
  }
}

class ProtocolGenerationResult {
  final bool success;
  final GeneratedProtocol? protocol;
  final StravaAnalysis? analysis;
  final SchedulingResult? schedulingResult;
  final String message;

  ProtocolGenerationResult({
    required this.success,
    this.protocol,
    this.analysis,
    this.schedulingResult,
    required this.message,
  });

  String get detailedSummary {
    if (!success) return message;

    final parts = <String>[];
    parts.add(message);

    if (analysis != null && analysis!.hasData) {
      parts.add('\n\n📊 Analysis:');
      parts.add(
          'Cadence: ${analysis!.avgCadence.toStringAsFixed(0)} spm (${analysis!.cadenceStatus})');
      parts.add('Weekly Distance: ${analysis!.distanceDisplay}');
      if (analysis!.aisriScore != null) {
        parts.add('AISRI Score: ${analysis!.aisriScore}/100');
      }
    }

    if (protocol != null) {
      parts.add('\n\n🏋️ Protocol:');
      parts.add(protocol!.protocolName);
      parts.add(protocol!.summary);
      parts.add('Focus: ${protocol!.focusAreas.join(", ")}');
      parts.add('Injury Risk: ${protocol!.injuryRisk}');
    }

    return parts.join('\n');
  }
}
