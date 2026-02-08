import 'package:supabase_flutter/supabase_flutter.dart';
import 'strava_analyzer.dart';
import 'dart:developer' as developer;

class ProtocolGenerator {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate a 2-week workout protocol based on Strava + AISRI data
  Future<GeneratedProtocol> generateProtocol({
    required StravaAnalysis analysis,
    required String athleteId,
    int durationWeeks = 2,
    int workoutsPerWeek = 3,
  }) async {
    // Identify focus areas
    final focusAreas = StravaAnalyzer.identifyFocusAreas(analysis);
    final injuryRisk = StravaAnalyzer.calculateInjuryRisk(analysis);

    developer.log('Focus areas: $focusAreas');
    developer.log('Injury risk: $injuryRisk');

    // Fetch exercises from database based on focus areas
    final exercises = await _fetchRelevantExercises(focusAreas);

    if (exercises.isEmpty) {
      throw Exception('No exercises found in database');
    }

    // Generate workouts
    final workouts = <GeneratedWorkout>[];

    for (int week = 1; week <= durationWeeks; week++) {
      for (int day = 1; day <= workoutsPerWeek; day++) {
        final workout = _generateWorkout(
          week: week,
          dayOfWeek: day,
          exercises: exercises,
          focusAreas: focusAreas,
          injuryRisk: injuryRisk,
        );
        workouts.add(workout);
      }
    }

    return GeneratedProtocol(
      protocolName: _generateProtocolName(focusAreas, injuryRisk),
      description: _generateDescription(analysis, focusAreas),
      durationWeeks: durationWeeks,
      workoutsPerWeek: workoutsPerWeek,
      workouts: workouts,
      focusAreas: focusAreas,
      injuryRisk: injuryRisk,
    );
  }

  // Fetch exercises from database based on focus areas
  Future<List<Map<String, dynamic>>> _fetchRelevantExercises(
      List<String> focusAreas) async {
    try {
      final List<String> categories = [];

      if (focusAreas.contains('mobility')) categories.add('Mobility');
      if (focusAreas.contains('strength')) categories.add('Strength');
      if (focusAreas.contains('balance')) categories.add('Balance');
      if (focusAreas.contains('flexibility')) categories.add('Mobility');
      if (focusAreas.contains('cadence')) categories.add('Cardio');

      // If no specific categories, get all
      if (categories.isEmpty) {
        categories.addAll(['Strength', 'Mobility', 'Balance']);
      }

      final response = await _supabase
          .from('exercises')
          .select()
          .inFilter('category', categories);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('Error fetching exercises: $e');
      return [];
    }
  }

  // Generate a single workout
  GeneratedWorkout _generateWorkout({
    required int week,
    required int dayOfWeek,
    required List<Map<String, dynamic>> exercises,
    required List<String> focusAreas,
    required String injuryRisk,
  }) {
    // Determine workout type based on day of week
    String workoutType;
    String workoutName;
    int duration;
    String difficulty;

    if (dayOfWeek == 1) {
      // Day 1: Mobility & Recovery
      workoutType = 'mobility';
      workoutName = 'Week $week - Mobility & Recovery';
      duration = 30;
      difficulty = 'easy';
    } else if (dayOfWeek == 2) {
      // Day 2: Strength
      workoutType = 'strength';
      workoutName = 'Week $week - Strength Training';
      duration = 45;
      difficulty = week == 1 ? 'moderate' : 'hard';
    } else {
      // Day 3: Balance & Prevention
      workoutType = 'rehab';
      workoutName = 'Week $week - Balance & Injury Prevention';
      duration = 35;
      difficulty = 'moderate';
    }

    // Select exercises for this workout
    final selectedExercises = _selectExercises(
      exercises: exercises,
      workoutType: workoutType,
      count: 6,
      focusAreas: focusAreas,
    );

    return GeneratedWorkout(
      workoutName: workoutName,
      workoutType: workoutType,
      exercises: selectedExercises,
      estimatedDuration: duration,
      difficulty: difficulty,
      week: week,
      dayOfWeek: dayOfWeek,
    );
  }

  // Select exercises for a workout
  List<Map<String, dynamic>> _selectExercises({
    required List<Map<String, dynamic>> exercises,
    required String workoutType,
    required int count,
    required List<String> focusAreas,
  }) {
    // Filter exercises by category matching workout type
    final filtered = exercises.where((ex) {
      final category = (ex['category'] as String).toLowerCase();

      if (workoutType == 'mobility') {
        return category == 'mobility';
      } else if (workoutType == 'strength') {
        return category == 'strength';
      } else if (workoutType == 'rehab') {
        return category == 'balance' || category == 'strength';
      }
      return true;
    }).toList();

    // If not enough exercises, add from all categories
    if (filtered.length < count) {
      final remaining =
          exercises.where((ex) => !filtered.contains(ex)).toList();
      filtered.addAll(remaining);
    }

    // Shuffle and take requested count
    filtered.shuffle();
    return filtered.take(count).toList();
  }

  // Generate protocol name
  String _generateProtocolName(List<String> focusAreas, String injuryRisk) {
    if (injuryRisk == 'high') {
      return 'Injury Prevention & Recovery Protocol';
    }

    if (focusAreas.contains('cadence')) {
      return 'Cadence Optimization Protocol';
    }

    if (focusAreas.contains('mobility')) {
      return 'Mobility & Flexibility Protocol';
    }

    if (focusAreas.contains('strength')) {
      return 'Runner Strength Protocol';
    }

    return 'Balanced Runner Development Protocol';
  }

  // Generate description
  String _generateDescription(
      StravaAnalysis analysis, List<String> focusAreas) {
    final parts = <String>[];

    parts.add(
        'Personalized protocol based on your Strava data and AISRI assessment.');

    if (analysis.avgCadence > 0) {
      parts.add(
          'Your average cadence is ${analysis.avgCadence.toStringAsFixed(0)} spm.');
    }

    if (analysis.aisriScore != null) {
      parts.add('AISRI Score: ${analysis.aisriScore}/100.');
    }

    parts.add('Focus areas: ${focusAreas.join(", ")}.');

    return parts.join(' ');
  }
}

class GeneratedProtocol {
  final String protocolName;
  final String description;
  final int durationWeeks;
  final int workoutsPerWeek;
  final List<GeneratedWorkout> workouts;
  final List<String> focusAreas;
  final String injuryRisk;

  GeneratedProtocol({
    required this.protocolName,
    required this.description,
    required this.durationWeeks,
    required this.workoutsPerWeek,
    required this.workouts,
    required this.focusAreas,
    required this.injuryRisk,
  });

  int get totalWorkouts => workouts.length;

  String get summary {
    return '$durationWeeks weeks • $workoutsPerWeek workouts/week • ${focusAreas.join(", ")} focus';
  }
}

class GeneratedWorkout {
  final String workoutName;
  final String workoutType;
  final List<Map<String, dynamic>> exercises;
  final int estimatedDuration;
  final String difficulty;
  final int week;
  final int dayOfWeek;

  GeneratedWorkout({
    required this.workoutName,
    required this.workoutType,
    required this.exercises,
    required this.estimatedDuration,
    required this.difficulty,
    required this.week,
    required this.dayOfWeek,
  });

  int get exerciseCount => exercises.length;

  List<String> get equipmentNeeded {
    final equipment = <String>{};
    for (var ex in exercises) {
      final needed = ex['equipment_needed'] as List?;
      if (needed != null) {
        equipment.addAll(needed.cast<String>());
      }
    }
    return equipment.toList();
  }
}
