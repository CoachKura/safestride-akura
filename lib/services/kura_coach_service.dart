import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kura Coach AI Workout Generator
/// Generates Garmin-compatible structured workouts based on AISRI methodology
class KuraCoachService {
  static final _supabase = Supabase.instance.client;

  // AISRI Training Zones
  static const Map<String, Map<String, dynamic>> trainingZones = {
    'AR': {
      'name': 'Active Recovery',
      'hrMin': 50,
      'hrMax': 60,
      'purpose': 'Recovery, Warm-up, Cool-down',
      'color': 0xFF90CAF9, // Light Blue
    },
    'F': {
      'name': 'Foundation',
      'hrMin': 60,
      'hrMax': 70,
      'purpose': 'Aerobic Base, Fat Burning, Stamina',
      'color': 0xFF64B5F6, // Blue
    },
    'EN': {
      'name': 'Endurance',
      'hrMin': 70,
      'hrMax': 80,
      'purpose': 'Aerobic Fitness, Improved Oxygen Efficiency',
      'color': 0xFF4DD0E1, // Cyan
    },
    'TH': {
      'name': 'Threshold',
      'hrMin': 80,
      'hrMax': 87,
      'purpose': 'Lactate Threshold, Anaerobic Capacity, Speed Endurance',
      'color': 0xFFFF9800, // Orange (CORE ZONE)
      'isCoreZone': true,
    },
    'P': {
      'name': 'Power',
      'hrMin': 87,
      'hrMax': 95,
      'purpose': 'Max Oxygen Uptake (VO2 Max), Peak Performance',
      'color': 0xFFFF5722, // Red
      'requiresSafetyGate': true,
    },
    'SP': {
      'name': 'Speed',
      'hrMin': 95,
      'hrMax': 100,
      'purpose': 'Anaerobic Power, Sprinting, Short Bursts',
      'color': 0xFFC62828, // Dark Red
      'requiresSafetyGate': true,
    },
  };

  /// Calculate AISRI Score (0-100)
  /// Formula: (Weighted HRV * 0.3) + (Recovery Status * 0.3) + 
  ///          (Load History * 0.2) + (Sleep Quality * 0.1) + (Subjective Feel * 0.1)
  static Future<double> calculateAISRIScore(String userId) async {
    try {
      // Fetch latest athlete data
      final response = await _supabase
          .from('athlete_profiles')
          .select('*, aisri_assessments(*)')
          .eq('user_id', userId)
          .single();

      final profile = response;
      final assessments = response['aisri_assessments'] as List?;

      if (assessments == null || assessments.isEmpty) {
        return 50.0; // Default moderate score
      }

      final latest = assessments.first;

      // Component scores (0-100 each)
      double runningPerformance = (latest['running_performance'] ?? 75).toDouble();
      double strength = (latest['strength_score'] ?? 75).toDouble();
      double rom = (latest['rom_score'] ?? 75).toDouble();
      double balance = (latest['balance_score'] ?? 75).toDouble();
      double mobility = (latest['mobility_score'] ?? 75).toDouble();
      double alignment = (latest['alignment_score'] ?? 75).toDouble();

      // AISRI weighted formula
      double aisriScore = 
          (runningPerformance * 0.40) +
          (strength * 0.15) +
          (rom * 0.12) +
          (balance * 0.13) +
          (mobility * 0.10) +
          (alignment * 0.10);

      return aisriScore.clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating AISRI score: $e');
      return 50.0;
    }
  }

  /// Determine allowed training zones based on AISRI score
  static List<String> getAllowedZones(double aisriScore) {
    if (aisriScore >= 85) {
      return ['AR', 'F', 'EN', 'TH', 'P', 'SP']; // All zones
    } else if (aisriScore >= 70) {
      return ['AR', 'F', 'EN', 'TH', 'P']; // +P
    } else if (aisriScore >= 55) {
      return ['AR', 'F', 'EN', 'TH']; // +TH
    } else if (aisriScore >= 40) {
      return ['AR', 'F', 'EN']; // +EN
    } else {
      return ['AR', 'F']; // AR, F only
    }
  }

  /// Check safety gates for high-intensity zones
  static Future<Map<String, bool>> checkSafetyGates(String userId) async {
    try {
      final response = await _supabase
          .from('athlete_profiles')
          .select('*, aisri_assessments(*), injuries(*)')
          .eq('user_id', userId)
          .single();

      final aisriScore = await calculateAISRIScore(userId);
      final assessments = response['aisri_assessments'] as List?;
      final injuries = response['injuries'] as List?;

      // Check for recent injuries (past 4 weeks)
      final recentInjuries = injuries?.where((injury) {
        final injuryDate = DateTime.parse(injury['injury_date']);
        final weeksDiff = DateTime.now().difference(injuryDate).inDays / 7;
        return weeksDiff <= 4 && injury['status'] != 'recovered';
      }).toList() ?? [];

      // Zone P (Power) Requirements
      bool zonePAllowed = aisriScore >= 70 &&
          (assessments?.first['rom_score'] ?? 0) >= 75 &&
          recentInjuries.isEmpty;

      // Zone SP (Speed) Requirements - stricter
      bool zoneSPAllowed = aisriScore >= 75 &&
          (assessments?.first['running_performance'] ?? 0) >= 75 &&
          (assessments?.first['strength_score'] ?? 0) >= 75 &&
          (assessments?.first['rom_score'] ?? 0) >= 75 &&
          (assessments?.first['balance_score'] ?? 0) >= 75 &&
          (assessments?.first['mobility_score'] ?? 0) >= 75 &&
          recentInjuries.isEmpty;

      return {
        'P': zonePAllowed,
        'SP': zoneSPAllowed,
      };
    } catch (e) {
      print('Error checking safety gates: $e');
      return {'P': false, 'SP': false};
    }
  }

  /// Generate weekly training schedule based on AISRI
  static Future<List<Map<String, dynamic>>> generateWeeklySchedule({
    required String userId,
    required String trainingPhase,
    required int weekNumber,
  }) async {
    final aisriScore = await calculateAISRIScore(userId);
    final allowedZones = getAllowedZones(aisriScore);
    final safetyGates = await checkSafetyGates(userId);

    // Weekly schedule template based on training phase
    Map<String, List<Map<String, dynamic>>> scheduleTemplates = {
      'Foundation': [
        {'day': 'Monday', 'zone': 'F', 'duration': 45, 'type': 'steady'},
        {'day': 'Tuesday', 'zone': 'EN', 'duration': 30, 'type': 'steady'},
        {'day': 'Wednesday', 'zone': 'AR', 'duration': 20, 'type': 'recovery'},
        {'day': 'Thursday', 'zone': 'TH', 'duration': 25, 'type': 'intervals', 'intervals': [
          {'work': 5, 'rest': 2, 'repeats': 4}
        ]},
        {'day': 'Friday', 'zone': 'F', 'duration': 45, 'type': 'steady'},
        {'day': 'Saturday', 'zone': 'P', 'duration': 20, 'type': 'intervals', 'intervals': [
          {'work': 3, 'rest': 3, 'repeats': 5}
        ]},
        {'day': 'Sunday', 'zone': 'AR', 'duration': 30, 'type': 'recovery'},
      ],
      'Endurance': [
        {'day': 'Monday', 'zone': 'F', 'duration': 50, 'type': 'steady'},
        {'day': 'Tuesday', 'zone': 'EN', 'duration': 40, 'type': 'steady'},
        {'day': 'Wednesday', 'zone': 'AR', 'duration': 25, 'type': 'recovery'},
        {'day': 'Thursday', 'zone': 'TH', 'duration': 35, 'type': 'tempo'},
        {'day': 'Friday', 'zone': 'F', 'duration': 40, 'type': 'steady'},
        {'day': 'Saturday', 'zone': 'EN', 'duration': 60, 'type': 'long_run'},
        {'day': 'Sunday', 'zone': 'AR', 'duration': 30, 'type': 'recovery'},
      ],
      'Threshold': [
        {'day': 'Monday', 'zone': 'F', 'duration': 40, 'type': 'steady'},
        {'day': 'Tuesday', 'zone': 'TH', 'duration': 30, 'type': 'intervals', 'intervals': [
          {'work': 8, 'rest': 3, 'repeats': 3}
        ]},
        {'day': 'Wednesday', 'zone': 'AR', 'duration': 25, 'type': 'recovery'},
        {'day': 'Thursday', 'zone': 'EN', 'duration': 45, 'type': 'steady'},
        {'day': 'Friday', 'zone': 'TH', 'duration': 25, 'type': 'tempo'},
        {'day': 'Saturday', 'zone': 'P', 'duration': 30, 'type': 'intervals', 'intervals': [
          {'work': 4, 'rest': 3, 'repeats': 6}
        ]},
        {'day': 'Sunday', 'zone': 'AR', 'duration': 35, 'type': 'recovery'},
      ],
      'Peak': [
        {'day': 'Monday', 'zone': 'F', 'duration': 35, 'type': 'steady'},
        {'day': 'Tuesday', 'zone': 'P', 'duration': 25, 'type': 'intervals', 'intervals': [
          {'work': 3, 'rest': 4, 'repeats': 6}
        ]},
        {'day': 'Wednesday', 'zone': 'AR', 'duration': 20, 'type': 'recovery'},
        {'day': 'Thursday', 'zone': 'TH', 'duration': 30, 'type': 'tempo'},
        {'day': 'Friday', 'zone': 'AR', 'duration': 20, 'type': 'recovery'},
        {'day': 'Saturday', 'zone': 'SP', 'duration': 20, 'type': 'intervals', 'intervals': [
          {'work': 1, 'rest': 5, 'repeats': 8}
        ]},
        {'day': 'Sunday', 'zone': 'EN', 'duration': 50, 'type': 'long_run'},
      ],
    };

    List<Map<String, dynamic>> schedule = scheduleTemplates[trainingPhase] ?? scheduleTemplates['Foundation']!;

    // Filter workouts based on allowed zones and safety gates
    List<Map<String, dynamic>> filteredSchedule = schedule.map((workout) {
      String zone = workout['zone'];
      
      // Check if zone is allowed
      if (!allowedZones.contains(zone)) {
        // Downgrade to highest allowed zone
        zone = allowedZones.last;
        workout = Map<String, dynamic>.from(workout);
        workout['zone'] = zone;
        workout['downgraded'] = true;
      }

      // Apply safety gates for P and SP zones
      if (zone == 'P' && !(safetyGates['P'] ?? false)) {
        workout = Map<String, dynamic>.from(workout);
        workout['zone'] = 'TH';
        workout['safety_gate_blocked'] = true;
      }
      if (zone == 'SP' && !(safetyGates['SP'] ?? false)) {
        workout = Map<String, dynamic>.from(workout);
        workout['zone'] = 'P';
        workout['safety_gate_blocked'] = true;
      }

      return workout;
    }).toList();

    return filteredSchedule;
  }

  /// Generate structured workout in Garmin-compatible format
  static Future<Map<String, dynamic>> generateStructuredWorkout({
    required String userId,
    required String workoutType,
    required String zone,
    required int durationMinutes,
    List<Map<String, dynamic>>? intervals,
  }) async {
    // Get user profile for HR calculation
    final profile = await _supabase
        .from('athlete_profiles')
        .select()
        .eq('user_id', userId)
        .single();

    final age = _calculateAge(profile['date_of_birth']);
    final maxHR = 208 - (0.7 * age);

    // Get zone HR ranges
    final zoneData = trainingZones[zone]!;
    final hrMin = ((maxHR * zoneData['hrMin'] / 100)).round();
    final hrMax = ((maxHR * zoneData['hrMax'] / 100)).round();

    // Estimate pace from HR zone (simplified)
    final paceMin = _estimatePaceFromHR(hrMin, age);
    final paceMax = _estimatePaceFromHR(hrMax, age);

    // Build workout steps for Garmin
    List<Map<String, dynamic>> workoutSteps = [];

    // Warm-up (always 10 minutes in AR zone)
    workoutSteps.add({
      'step_type': 'warmup',
      'duration_type': 'time',
      'duration_value': 10 * 60, // seconds
      'target_type': 'heart_rate',
      'target_min': ((maxHR * 50 / 100)).round(),
      'target_max': ((maxHR * 60 / 100)).round(),
      'description': 'Warm-up: Easy pace',
    });

    // Main workout
    if (intervals != null && intervals.isNotEmpty) {
      // Interval workout
      for (var interval in intervals) {
        for (int i = 0; i < interval['repeats']; i++) {
          // Work interval
          workoutSteps.add({
            'step_type': 'interval',
            'duration_type': 'time',
            'duration_value': interval['work'] * 60,
            'target_type': 'heart_rate',
            'target_min': hrMin,
            'target_max': hrMax,
            'description': 'Interval $zone: ${interval['work']} min',
          });

          // Rest interval
          workoutSteps.add({
            'step_type': 'recovery',
            'duration_type': 'time',
            'duration_value': interval['rest'] * 60,
            'target_type': 'heart_rate',
            'target_min': ((maxHR * 50 / 100)).round(),
            'target_max': ((maxHR * 65 / 100)).round(),
            'description': 'Recovery: ${interval['rest']} min',
          });
        }
      }
    } else {
      // Steady-state workout
      workoutSteps.add({
        'step_type': 'run',
        'duration_type': 'time',
        'duration_value': durationMinutes * 60,
        'target_type': 'heart_rate',
        'target_min': hrMin,
        'target_max': hrMax,
        'description': '$zone Zone: $durationMinutes min',
      });
    }

    // Cool-down (always 5 minutes in AR zone)
    workoutSteps.add({
      'step_type': 'cooldown',
      'duration_type': 'time',
      'duration_value': 5 * 60,
      'target_type': 'heart_rate',
      'target_min': ((maxHR * 50 / 100)).round(),
      'target_max': ((maxHR * 60 / 100)).round(),
      'description': 'Cool-down: Easy pace',
    });

    return {
      'workout_name': '${zoneData['name']} $workoutType',
      'workout_type': workoutType,
      'zone': zone,
      'zone_name': zoneData['name'],
      'duration_minutes': durationMinutes,
      'hr_min': hrMin,
      'hr_max': hrMax,
      'pace_min': paceMin,
      'pace_max': paceMax,
      'estimated_distance': _estimateDistance(durationMinutes, paceMin, paceMax),
      'workout_steps': workoutSteps,
      'intervals': intervals,
      'garmin_compatible': true,
    };
  }

  /// Save workout plan to database
  static Future<String> saveWorkoutPlan({
    required String userId,
    required String planName,
    required String trainingPhase,
    required List<Map<String, dynamic>> weeklySchedule,
    required DateTime startDate,
    required int durationWeeks,
  }) async {
    try {
      // Insert plan
      final planResponse = await _supabase
          .from('ai_workout_plans')
          .insert({
            'user_id': userId,
            'plan_name': planName,
            'training_phase': trainingPhase,
            'start_date': startDate.toIso8601String(),
            'end_date': startDate.add(Duration(days: durationWeeks * 7)).toIso8601String(),
            'duration_weeks': durationWeeks,
            'status': 'active',
            'metadata': {
              'weekly_schedule': weeklySchedule,
              'generated_by': 'kura_coach_ai',
              'aisri_based': true,
            },
          })
          .select()
          .single();

      final planId = planResponse['id'];

      // Generate and insert individual workouts
      for (int week = 0; week < durationWeeks; week++) {
        for (var dayWorkout in weeklySchedule) {
          final workoutDate = startDate.add(Duration(days: week * 7 + _getDayOffset(dayWorkout['day'])));

          final structuredWorkout = await generateStructuredWorkout(
            userId: userId,
            workoutType: dayWorkout['type'] ?? 'steady',
            zone: dayWorkout['zone'],
            durationMinutes: dayWorkout['duration'],
            intervals: dayWorkout['intervals'],
          );

          await _supabase.from('ai_workouts').insert({
            'user_id': userId,
            'plan_id': planId,
            'workout_date': workoutDate.toIso8601String(),
            'workout_name': structuredWorkout['workout_name'],
            'workout_type': structuredWorkout['workout_type'],
            'zone': structuredWorkout['zone'],
            'duration_minutes': structuredWorkout['duration_minutes'],
            'target_hr_min': structuredWorkout['hr_min'],
            'target_hr_max': structuredWorkout['hr_max'],
            'target_pace_min': structuredWorkout['pace_min'],
            'target_pace_max': structuredWorkout['pace_max'],
            'estimated_distance': structuredWorkout['estimated_distance'],
            'workout_structure': structuredWorkout['workout_steps'],
            'intervals': structuredWorkout['intervals'],
            'status': 'scheduled',
            'garmin_compatible': true,
          });
        }
      }

      return planId;
    } catch (e) {
      print('Error saving workout plan: $e');
      throw Exception('Failed to save workout plan: $e');
    }
  }

  // Helper functions
  static int _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 30; // Default age
    final dob = DateTime.parse(dateOfBirth);
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  static String _estimatePaceFromHR(int hr, int age) {
    // Simplified pace estimation (min/km)
    // Lower HR = slower pace, higher HR = faster pace
    final maxHR = 208 - (0.7 * age);
    final hrPercent = hr / maxHR;
    
    double paceMinPerKm;
    if (hrPercent < 0.6) {
      paceMinPerKm = 7.0; // Easy pace
    } else if (hrPercent < 0.7) {
      paceMinPerKm = 6.0; // Foundation pace
    } else if (hrPercent < 0.8) {
      paceMinPerKm = 5.5; // Endurance pace
    } else if (hrPercent < 0.87) {
      paceMinPerKm = 5.0; // Threshold pace
    } else if (hrPercent < 0.95) {
      paceMinPerKm = 4.5; // Power pace
    } else {
      paceMinPerKm = 4.0; // Speed pace
    }

    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static double _estimateDistance(int durationMinutes, String paceMin, String paceMax) {
    // Parse pace strings (format: "5:30")
    final minParts = paceMin.split(':');
    final maxParts = paceMax.split(':');
    final avgPaceMinutes = 
        (int.parse(minParts[0]) + int.parse(maxParts[0])) / 2 +
        (int.parse(minParts[1]) + int.parse(maxParts[1])) / 120;

    return durationMinutes / avgPaceMinutes;
  }

  static int _getDayOffset(String day) {
    const days = {
      'Monday': 0,
      'Tuesday': 1,
      'Wednesday': 2,
      'Thursday': 3,
      'Friday': 4,
      'Saturday': 5,
      'Sunday': 6,
    };
    return days[day] ?? 0;
  }

  /// Generate training protocol from AISRI evaluation
  static Future<void> generateProtocolFromEvaluation({
    required String athleteId,
    required Map<String, dynamic> evaluationData,
  }) async {
    try {
      // Extract key metrics
      final aisriScore = evaluationData['aisri_score'] as double;
      final fitnessLevel = evaluationData['fitness_level'] as String;
      final injuryRisk = evaluationData['injury_risk'] as String;
      final pillarScores = evaluationData['pillar_scores'] as Map<String, dynamic>;

      // Determine protocol duration (8-16 weeks based on fitness level)
      final protocolWeeks = _calculateProtocolDuration(fitnessLevel, injuryRisk);
      
      // Determine training frequency (3-6 days per week)
      final weeklyFrequency = _calculateWeeklyFrequency(fitnessLevel, aisriScore);
      
      // Calculate target volume
      final weeklyVolume = _calculateWeeklyVolume(fitnessLevel, aisriScore);
      
      // Identify weak areas from pillar scores
      final weakAreas = _identifyWeakAreas(pillarScores);
      
      // Create initial athlete goals entry
      await _supabase.from('athlete_goals').insert({
        'user_id': athleteId,
        'generated_from_evaluation': true,
        'evaluation_date': evaluationData['assessment_date'],
        'aisri_score': aisriScore,
        'fitness_level': fitnessLevel,
        'injury_risk': injuryRisk,
        'recommended_weekly_frequency': weeklyFrequency,
        'recommended_weekly_volume': weeklyVolume,
        'focus_areas': weakAreas,
        'protocol_duration_weeks': protocolWeeks,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Generate initial 4-week training plan
      await _generateInitialTrainingPlan(
        athleteId: athleteId,
        fitnessLevel: fitnessLevel,
        weeklyFrequency: weeklyFrequency,
        weeklyVolume: weeklyVolume,
        focusAreas: weakAreas,
      );

      developer.log('Protocol generated successfully for athlete: $athleteId');
      
    } catch (e, stackTrace) {
      developer.log(
        'Error generating protocol from evaluation',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static int _calculateProtocolDuration(String fitnessLevel, String injuryRisk) {
    // Base duration
    int weeks = 12;
    
    // Adjust for fitness level
    switch (fitnessLevel) {
      case 'beginner':
        weeks = 16; // Longer adaptation period
        break;
      case 'intermediate':
        weeks = 12; // Standard duration
        break;
      case 'advanced':
        weeks = 10; // More efficient progression
        break;
    }
    
    // Adjust for injury risk
    if (injuryRisk == 'high' || injuryRisk == 'High') {
      weeks += 2; // Extra time for careful progression
    }
    
    return weeks;
  }

  static int _calculateWeeklyFrequency(String fitnessLevel, double aisriScore) {
    // Beginners: 3-4 days, Intermediate: 4-5 days, Advanced: 5-6 days
    switch (fitnessLevel) {
      case 'beginner':
        return aisriScore >= 50 ? 4 : 3;
      case 'intermediate':
        return aisriScore >= 70 ? 5 : 4;
      case 'advanced':
        return aisriScore >= 85 ? 6 : 5;
      default:
        return 4;
    }
  }

  static double _calculateWeeklyVolume(String fitnessLevel, double aisriScore) {
    // Weekly volume in kilometers
    switch (fitnessLevel) {
      case 'beginner':
        return aisriScore >= 50 ? 25.0 : 20.0;
      case 'intermediate':
        return aisriScore >= 70 ? 45.0 : 35.0;
      case 'advanced':
        return aisriScore >= 85 ? 70.0 : 55.0;
      default:
        return 30.0;
    }
  }

  static List<String> _identifyWeakAreas(Map<String, dynamic> pillarScores) {
    final weakAreas = <String>[];
    final threshold = 65.0; // Scores below this are considered weak
    
    pillarScores.forEach((pillar, score) {
      if (score < threshold) {
        weakAreas.add(pillar);
      }
    });
    
    // If no weak areas, focus on balanced development
    if (weakAreas.isEmpty) {
      weakAreas.add('balanced_development');
    }
    
    return weakAreas;
  }

  static Future<void> _generateInitialTrainingPlan({
    required String athleteId,
    required String fitnessLevel,
    required int weeklyFrequency,
    required double weeklyVolume,
    required List<String> focusAreas,
  }) async {
    // Generate 4 weeks of workouts
    final startDate = DateTime.now();
    
    for (int week = 1; week <= 4; week++) {
      // Calculate weekly progression (start at 80%, build to 100%)
      final weekMultiplier = 0.8 + (week * 0.05);
      final weekVolume = weeklyVolume * weekMultiplier;
      
      // Generate workouts for this week
      final workouts = _generateWeekWorkouts(
        weekNumber: week,
        frequency: weeklyFrequency,
        weeklyVolume: weekVolume,
        fitnessLevel: fitnessLevel,
        focusAreas: focusAreas,
      );
      
      // Insert workouts into calendar
      for (int day = 0; day < workouts.length; day++) {
        final workoutDate = startDate.add(Duration(days: (week - 1) * 7 + day));
        
        await _supabase.from('athlete_calendar').insert({
          'user_id': athleteId,
          'workout_date': workoutDate.toIso8601String().split('T')[0],
          'workout_type': workouts[day]['type'],
          'workout_name': workouts[day]['name'],
          'description': workouts[day]['description'],
          'target_distance': workouts[day]['distance'],
          'target_duration': workouts[day]['duration'],
          'aisri_zone': workouts[day]['zone'],
          'intensity': workouts[day]['intensity'],
          'status': 'scheduled',
          'week_number': week,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  static List<Map<String, dynamic>> _generateWeekWorkouts({
    required int weekNumber,
    required int frequency,
    required double weeklyVolume,
    required String fitnessLevel,
    required List<String> focusAreas,
  }) {
    final workouts = <Map<String, dynamic>>[];
    
    // Distribute volume across workouts
    final avgWorkoutDistance = weeklyVolume / frequency;
    
    // Week structure based on frequency
    if (frequency <= 3) {
      // 3 days: Easy, Tempo, Long
      workouts.addAll([
        _createWorkout('easy_run', avgWorkoutDistance * 0.8, 'Zone F'),
        _createWorkout('tempo_run', avgWorkoutDistance * 0.9, 'Zone TH'),
        _createWorkout('long_run', avgWorkoutDistance * 1.3, 'Zone EN'),
      ]);
    } else if (frequency == 4) {
      // 4 days: Easy, Tempo, Easy, Long
      workouts.addAll([
        _createWorkout('easy_run', avgWorkoutDistance * 0.7, 'Zone F'),
        _createWorkout('tempo_run', avgWorkoutDistance * 1.0, 'Zone TH'),
        _createWorkout('easy_run', avgWorkoutDistance * 0.8, 'Zone F'),
        _createWorkout('long_run', avgWorkoutDistance * 1.5, 'Zone EN'),
      ]);
    } else if (frequency == 5) {
      // 5 days: Easy, Intervals, Easy, Tempo, Long
      workouts.addAll([
        _createWorkout('easy_run', avgWorkoutDistance * 0.6, 'Zone F'),
        _createWorkout('intervals', avgWorkoutDistance * 0.8, 'Zone P'),
        _createWorkout('easy_run', avgWorkoutDistance * 0.7, 'Zone F'),
        _createWorkout('tempo_run', avgWorkoutDistance * 1.0, 'Zone TH'),
        _createWorkout('long_run', avgWorkoutDistance * 1.9, 'Zone EN'),
      ]);
    } else {
      // 6 days: Easy, Intervals, Easy, Tempo, Easy, Long
      workouts.addAll([
        _createWorkout('easy_run', avgWorkoutDistance * 0.5, 'Zone F'),
        _createWorkout('intervals', avgWorkoutDistance * 0.8, 'Zone P'),
        _createWorkout('easy_run', avgWorkoutDistance * 0.6, 'Zone F'),
        _createWorkout('tempo_run', avgWorkoutDistance * 1.0, 'Zone TH'),
        _createWorkout('easy_run', avgWorkoutDistance * 0.7, 'Zone F'),
        _createWorkout('long_run', avgWorkoutDistance * 2.4, 'Zone EN'),
      ]);
    }
    
    return workouts;
  }

  static Map<String, dynamic> _createWorkout(String type, double distance, String zone) {
    final workoutDetails = {
      'easy_run': {
        'name': 'Easy Run',
        'description': 'Comfortable pace run for aerobic base development',
        'intensity': 0.65,
      },
      'tempo_run': {
        'name': 'Tempo Run',
        'description': 'Sustained effort at threshold pace',
        'intensity': 0.85,
      },
      'intervals': {
        'name': 'Interval Training',
        'description': 'High-intensity intervals with recovery',
        'intensity': 0.90,
      },
      'long_run': {
        'name': 'Long Run',
        'description': 'Extended duration run for endurance',
        'intensity': 0.70,
      },
    };
    
    final details = workoutDetails[type]!;
    
    return {
      'type': type,
      'name': details['name'],
      'description': details['description'],
      'distance': distance.roundToDouble(),
      'duration': (distance * 6.5).round(), // Estimate ~6.5 min/km pace
      'zone': zone,
      'intensity': details['intensity'],
    };
  }
}
