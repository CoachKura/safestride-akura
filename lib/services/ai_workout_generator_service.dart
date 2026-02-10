import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIWorkoutGeneratorService {
  /// Generate a personalized training plan based on athlete's goal
  static Future<Map<String, dynamic>> generateWorkoutPlan({
    required String goalType, // 'marathon', '10k', '5k', 'fitness', 'weight_loss'
    required int weeksToGoal,
    required int currentWeeklyKm,
    required int trainingDaysPerWeek,
    required String fitnessLevel, // 'beginner', 'intermediate', 'advanced'
    required double AISRIScore,
    String? targetRaceDate,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Get athlete profile for personalization
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('date_of_birth')
        .eq('id', userId)
        .maybeSingle();

    final age = profile != null ? _calculateAge(profile['date_of_birth']) : 30;
    final maxHR = (208 - (0.7 * age)).round();

    // Calculate weekly progression
    final weeklyProgression = _calculateWeeklyProgression(
      goalType: goalType,
      weeksToGoal: weeksToGoal,
      currentWeeklyKm: currentWeeklyKm,
      fitnessLevel: fitnessLevel,
      AISRIScore: AISRIScore,
    );

    // Generate workouts for each week
    final workouts = <Map<String, dynamic>>[];
    final startDate = DateTime.now();

    for (int week = 0; week < weeksToGoal; week++) {
      final weeklyWorkouts = _generateWeekWorkouts(
        week: week,
        totalWeeks: weeksToGoal,
        weeklyKm: weeklyProgression[week],
        trainingDaysPerWeek: trainingDaysPerWeek,
        goalType: goalType,
        fitnessLevel: fitnessLevel,
        maxHR: maxHR,
        startDate: startDate.add(Duration(days: week * 7)),
        AISRIScore: AISRIScore,
      );
      
      workouts.addAll(weeklyWorkouts);
    }

    return {
      'goal_type': goalType,
      'total_weeks': weeksToGoal,
      'total_workouts': workouts.length,
      'weekly_progression': weeklyProgression,
      'workouts': workouts,
      'target_race_date': targetRaceDate,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Save generated workouts to calendar
  static Future<void> saveWorkoutsToCalendar(
      List<Map<String, dynamic>> workouts) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Get athlete profile id
    final profileResponse = await Supabase.instance.client
        .from('athlete_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (profileResponse == null) {
      print('No athlete profile found for user');
      return;
    }

    final athleteId = profileResponse['id'];

    // First, create a generic workout template if needed
    for (var workout in workouts) {
      try {
        // Create workout template
        final workoutTemplate = await Supabase.instance.client
            .from('workouts')
            .insert({
          'workout_name': workout['type'],
          'workout_type': 'cardio',
          'exercises': [],
          'estimated_duration_minutes': workout['duration_minutes'],
          'difficulty': workout['intensity'] == 'high' ? 'hard' : workout['intensity'] == 'low' ? 'easy' : 'moderate',
          'description': workout['description'],
        })
            .select('id')
            .single();

        // Create calendar entry
        await Supabase.instance.client.from('athlete_calendar').insert({
          'athlete_id': athleteId,
          'workout_id': workoutTemplate['id'],
          'scheduled_date': workout['scheduled_date'].toString().split('T')[0],
          'status': 'pending',
          'athlete_notes': workout['notes'],
          'is_ai_generated': true,
          'target_hr_min': workout['hr_zone_min'],
          'target_hr_max': workout['hr_zone_max'],
          'intensity': workout['intensity'],
          'week_number': workout['week_number'],
          'workout_type': workout['type'],
          'distance_km': workout['distance_km'],
          'duration_minutes': workout['duration_minutes'],
          'description': workout['description'],
        });
      } catch (e) {
        print('Error saving workout: $e');
      }
    }
  }

  /// Calculate age from date of birth
  static int _calculateAge(String? dobStr) {
    if (dobStr == null) return 30;
    final dob = DateTime.parse(dobStr);
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Calculate weekly distance progression
  static List<double> _calculateWeeklyProgression({
    required String goalType,
    required int weeksToGoal,
    required int currentWeeklyKm,
    required String fitnessLevel,
    required double AISRIScore,
  }) {
    // Target weekly distances by goal type
    final targetDistances = {
      'marathon': 70.0,
      'half_marathon': 50.0,
      '10k': 35.0,
      '5k': 25.0,
      'fitness': 30.0,
      'weight_loss': 25.0,
    };

    final targetKm = targetDistances[goalType] ?? 30.0;
    final startKm = currentWeeklyKm.toDouble();

    // Adjust progression rate based on fitness level and AISRI
    double progressionRate = 1.10; // 10% per week default
    if (fitnessLevel == 'beginner' || AISRIScore < 60) {
      progressionRate = 1.08; // 8% safer progression
    } else if (fitnessLevel == 'advanced' && AISRIScore > 75) {
      progressionRate = 1.12; // 12% aggressive progression
    }

    final progression = <double>[];
    double currentKm = startKm;

    for (int week = 0; week < weeksToGoal; week++) {
      // Build weeks with gradual increase
      if (week < weeksToGoal * 0.7) {
        currentKm = min(currentKm * progressionRate, targetKm);
      }
      // Peak weeks
      else if (week < weeksToGoal * 0.9) {
        currentKm = targetKm;
      }
      // Taper weeks
      else {
        currentKm = targetKm * 0.7;
      }

      progression.add(currentKm);
    }

    return progression;
  }

  /// Generate workouts for a specific week
  static List<Map<String, dynamic>> _generateWeekWorkouts({
    required int week,
    required int totalWeeks,
    required double weeklyKm,
    required int trainingDaysPerWeek,
    required String goalType,
    required String fitnessLevel,
    required int maxHR,
    required DateTime startDate,
    required double AISRIScore,
  }) {
    final workouts = <Map<String, dynamic>>[];
    final random = Random(week); // Consistent random for same week

    // Determine workout types distribution
    final workoutTypes = _getWorkoutDistribution(
      goalType: goalType,
      trainingDaysPerWeek: trainingDaysPerWeek,
      week: week,
      totalWeeks: totalWeeks,
    );

    // Distribute weekly distance across workouts
    var remainingKm = weeklyKm;
    final workoutDays = [1, 3, 5, 0, 2, 4, 6]; // Mon, Wed, Fri, Sun, Tue, Thu, Sat priority

    for (int i = 0; i < trainingDaysPerWeek && i < workoutTypes.length; i++) {
      final workoutType = workoutTypes[i];
      final dayOffset = workoutDays[i];
      
      // Calculate distance for this workout
      final distancePercent = _getDistancePercent(workoutType, i, trainingDaysPerWeek);
      final distance = (weeklyKm * distancePercent).clamp(3.0, 25.0);
      remainingKm -= distance;

      // Calculate duration based on pace
      final pace = _calculatePace(fitnessLevel, workoutType);
      final duration = (distance * pace).round();

      // Get HR zones
      final hrZones = _getHRZones(workoutType, maxHR);

      final workout = {
        'scheduled_date': startDate.add(Duration(days: dayOffset)).toIso8601String(),
        'type': _getWorkoutTypeName(workoutType),
        'workout_category': workoutType,
        'duration_minutes': duration,
        'distance_km': distance,
        'intensity': _getIntensity(workoutType),
        'hr_zone_min': hrZones['min'],
        'hr_zone_max': hrZones['max'],
        'pace_target': pace,
        'description': _generateDescription(workoutType, distance, week, totalWeeks),
        'notes': _generateNotes(workoutType, AISRIScore, fitnessLevel),
        'week_number': week + 1,
      };

      workouts.add(workout);
    }

    return workouts;
  }

  /// Get workout type distribution for the week
  static List<String> _getWorkoutDistribution({
    required String goalType,
    required int trainingDaysPerWeek,
    required int week,
    required int totalWeeks,
  }) {
    // Base distribution patterns
    final distributions = {
      3: ['easy', 'tempo', 'long'],
      4: ['easy', 'tempo', 'intervals', 'long'],
      5: ['easy', 'tempo', 'easy', 'intervals', 'long'],
      6: ['easy', 'tempo', 'easy', 'intervals', 'easy', 'long'],
      7: ['easy', 'tempo', 'easy', 'intervals', 'recovery', 'easy', 'long'],
    };

    // Adjust for taper phase (last 2 weeks)
    if (week >= totalWeeks - 2) {
      return List.generate(
          trainingDaysPerWeek, (i) => i == trainingDaysPerWeek - 1 ? 'easy' : 'recovery');
    }

    return distributions[trainingDaysPerWeek] ??
        List.generate(trainingDaysPerWeek, (i) => 'easy');
  }

  /// Get distance percentage for workout type
  static double _getDistancePercent(String type, int index, int totalWorkouts) {
    switch (type) {
      case 'long':
        return 0.35; // 35% of weekly distance
      case 'tempo':
        return 0.25; // 25%
      case 'intervals':
        return 0.20; // 20%
      case 'easy':
        return 0.15; // 15%
      case 'recovery':
        return 0.10; // 10%
      default:
        return 1.0 / totalWorkouts;
    }
  }

  /// Calculate pace in minutes per km
  static double _calculatePace(String fitnessLevel, String workoutType) {
    final basePaces = {
      'beginner': 7.0,
      'intermediate': 6.0,
      'advanced': 5.0,
    };

    final basePace = basePaces[fitnessLevel] ?? 6.0;

    final paceModifiers = {
      'recovery': 1.3,
      'easy': 1.2,
      'tempo': 1.0,
      'intervals': 0.9,
      'long': 1.15,
    };

    return basePace * (paceModifiers[workoutType] ?? 1.0);
  }

  /// Get HR zones for workout type
  static Map<String, int> _getHRZones(String workoutType, int maxHR) {
    final zones = {
      'recovery': {'min': (maxHR * 0.50).round(), 'max': (maxHR * 0.60).round()},
      'easy': {'min': (maxHR * 0.60).round(), 'max': (maxHR * 0.70).round()},
      'tempo': {'min': (maxHR * 0.80).round(), 'max': (maxHR * 0.87).round()},
      'intervals': {'min': (maxHR * 0.87).round(), 'max': (maxHR * 0.95).round()},
      'long': {'min': (maxHR * 0.65).round(), 'max': (maxHR * 0.75).round()},
    };

    return zones[workoutType] ?? {'min': (maxHR * 0.60).round(), 'max': (maxHR * 0.70).round()};
  }

  /// Get intensity level
  static String _getIntensity(String workoutType) {
    final intensities = {
      'recovery': 'low',
      'easy': 'low',
      'tempo': 'moderate',
      'intervals': 'high',
      'long': 'moderate',
    };
    return intensities[workoutType] ?? 'moderate';
  }

  /// Get workout type name
  static String _getWorkoutTypeName(String type) {
    switch (type) {
      case 'recovery':
        return 'Recovery Run';
      case 'easy':
        return 'Easy Run';
      case 'tempo':
        return 'Tempo Run';
      case 'intervals':
        return 'Interval Training';
      case 'long':
        return 'Long Run';
      default:
        return 'Training Run';
    }
  }

  /// Generate workout description
  static String _generateDescription(String type, double distance, int week, int totalWeeks) {
    final weekPhase = week < totalWeeks * 0.7
        ? 'Base Building'
        : week < totalWeeks * 0.9
            ? 'Peak Training'
            : 'Taper';

    switch (type) {
      case 'recovery':
        return '🟢 Recovery Run - Light pace to promote recovery. Focus on form. ($weekPhase: Week ${week + 1})';
      case 'easy':
        return '🟢 Easy Run - Comfortable conversational pace. Build aerobic base. ($weekPhase: Week ${week + 1})';
      case 'tempo':
        return '🟡 Tempo Run - Comfortably hard pace. ${distance > 10 ? '30min tempo in middle' : '20min tempo'}. ($weekPhase: Week ${week + 1})';
      case 'intervals':
        return '🔴 Intervals - ${distance > 8 ? '6x800m' : '5x400m'} at 5K pace with equal rest. ($weekPhase: Week ${week + 1})';
      case 'long':
        return '🔵 Long Run - Build endurance. Keep effort easy-moderate. ($weekPhase: Week ${week + 1})';
      default:
        return 'Training run - ${distance.toStringAsFixed(1)}km ($weekPhase: Week ${week + 1})';
    }
  }

  /// Generate workout notes
  static String _generateNotes(String type, double AISRIScore, String fitnessLevel) {
    final notes = <String>[];

    // AISRI-based recommendations
    if (AISRIScore < 60) {
      notes.add('⚠️ AISRI below 60 - Focus on form and recovery');
    } else if (AISRIScore > 75) {
      notes.add('✅ AISRI good - Ready for quality work');
    }

    // Workout-specific tips
    switch (type) {
      case 'recovery':
        notes.add('🎯 Keep HR in Zone 1-2. Walk if needed.');
        break;
      case 'easy':
        notes.add('🎯 Should feel easy throughout. Build aerobic base.');
        break;
      case 'tempo':
        notes.add('🎯 Comfortably hard pace. Should be able to say short phrases.');
        notes.add('⏱️ Warm up 10-15min, tempo effort middle, cool down 10min.');
        break;
      case 'intervals':
        notes.add('🎯 High effort intervals with full recovery between.');
        notes.add('⏱️ 15min warm-up, intervals, 10min cool-down.');
        break;
      case 'long':
        notes.add('🎯 Steady easy-moderate pace. Focus on duration.');
        notes.add('💧 Bring water/fuel for runs over 90min.');
        break;
    }

    // Fitness level tips
    if (fitnessLevel == 'beginner') {
      notes.add('💡 Take walk breaks as needed. Listen to your body.');
    }

    return notes.join('\n');
  }

  /// Quick workout suggestion for today based on recent activity
  static Future<Map<String, dynamic>> suggestTodayWorkout() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check recent workouts (last 7 days)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentWorkouts = await Supabase.instance.client
        .from('workouts')
        .select('created_at, duration_minutes, distance_km, workout_type')
        .eq('user_id', userId)
        .gte('created_at', sevenDaysAgo.toIso8601String())
        .order('created_at', ascending: false);

    // Get profile for HR calculation
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('date_of_birth')
        .eq('id', userId)
        .maybeSingle();

    final age = _calculateAge(profile?['date_of_birth']);
    final maxHR = (208 - (0.7 * age)).round();

    // Analyze recent activity
    final daysSinceLastWorkout = recentWorkouts.isEmpty
        ? 7
        : DateTime.now()
            .difference(DateTime.parse(recentWorkouts[0]['created_at']))
            .inDays;

    final weeklyDistance = recentWorkouts.fold(
        0.0, (sum, w) => sum + ((w['distance_km'] ?? 0.0) as num).toDouble());

    // Suggest workout based on recent pattern
    String suggestedType;
    if (daysSinceLastWorkout > 2) {
      suggestedType = 'easy'; // Easy comeback
    } else if (weeklyDistance < 20) {
      suggestedType = 'easy'; // Build volume
    } else if (recentWorkouts.length >= 3) {
      suggestedType = 'tempo'; // Ready for quality
    } else {
      suggestedType = 'easy';
    }

    final hrZones = _getHRZones(suggestedType, maxHR);

    return {
      'type': _getWorkoutTypeName(suggestedType),
      'category': suggestedType,
      'suggested_distance': suggestedType == 'easy' ? 5.0 : 8.0,
      'suggested_duration': suggestedType == 'easy' ? 35 : 50,
      'intensity': _getIntensity(suggestedType),
      'hr_zone_min': hrZones['min'],
      'hr_zone_max': hrZones['max'],
      'description': _generateDescription(suggestedType, 5.0, 0, 1),
      'rationale': _getSuggestionRationale(
          daysSinceLastWorkout, weeklyDistance, recentWorkouts.length),
    };
  }

  static String _getSuggestionRationale(
      int daysSinceLastWorkout, double weeklyDistance, int workoutCount) {
    if (daysSinceLastWorkout > 2) {
      return 'It\'s been $daysSinceLastWorkout days since your last workout. Start with an easy run.';
    } else if (weeklyDistance < 20) {
      return 'Weekly volume is ${weeklyDistance.toStringAsFixed(1)}km. Focus on building base with easy runs.';
    } else if (workoutCount >= 3) {
      return 'You\'ve been consistent! Ready for a quality session.';
    }
    return 'Continue building your fitness with steady training.';
  }
}
