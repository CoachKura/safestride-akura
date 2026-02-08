import 'package:flutter/material.dart';

class WorkoutCalendarEntry {
  final String id;
  final String athleteId;
  final String workoutId;
  final DateTime scheduledDate;
  final TimeOfDay? scheduledTime;
  final String status; // pending, completed, skipped, rescheduled
  final DateTime? completedAt;
  final int? actualDurationMinutes;
  final int? difficultyRating; // 1-5
  final int? painLevel; // 0-10
  final String? athleteNotes;
  final bool reminderSent;
  final Workout workout;

  WorkoutCalendarEntry({
    required this.id,
    required this.athleteId,
    required this.workoutId,
    required this.scheduledDate,
    this.scheduledTime,
    required this.status,
    this.completedAt,
    this.actualDurationMinutes,
    this.difficultyRating,
    this.painLevel,
    this.athleteNotes,
    this.reminderSent = false,
    required this.workout,
  });

  // Helper getters
  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return scheduledDate.year == tomorrow.year &&
        scheduledDate.month == tomorrow.month &&
        scheduledDate.day == tomorrow.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return scheduledDate.year == yesterday.year &&
        scheduledDate.month == yesterday.month &&
        scheduledDate.day == yesterday.day;
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';
  bool get isRescheduled => status == 'rescheduled';

  // From JSON
  factory WorkoutCalendarEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutCalendarEntry(
      id: json['id'] as String,
      athleteId: json['athlete_id'] as String,
      workoutId: json['workout_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] != null
          ? _parseTimeOfDay(json['scheduled_time'] as String)
          : null,
      status: json['status'] as String,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      actualDurationMinutes: json['actual_duration_minutes'] as int?,
      difficultyRating: json['difficulty_rating'] as int?,
      painLevel: json['pain_level'] as int?,
      athleteNotes: json['athlete_notes'] as String?,
      reminderSent: json['reminder_sent'] as bool? ?? false,
      workout: Workout.fromJson(json['workouts'] as Map<String, dynamic>),
    );
  }

  // From GPS Activity (Strava, Garmin, Coros)
  factory WorkoutCalendarEntry.fromGpsActivity(Map<String, dynamic> json) {
    final startTime = DateTime.parse(json['start_time'] as String);
    final distanceKm =
        ((json['distance_meters'] as num) / 1000).toStringAsFixed(2);
    final durationMin = ((json['duration_seconds'] as int) / 60).round();
    final platform = json['platform'] as String;
    final activityType = json['activity_type'] as String? ?? 'Run';

    // Create workout name from activity data
    final workoutName = '🏃 $activityType - $distanceKm km ($platform)';

    // Build workout description from available metrics
    final List<String> details = [];
    if (json['avg_cadence'] != null) {
      details.add('Cadence: ${(json['avg_cadence'] as num).round()} spm');
    }
    if (json['avg_heart_rate'] != null) {
      details.add('HR: ${(json['avg_heart_rate'] as num).round()} bpm');
    }
    if (json['avg_pace'] != null) {
      details
          .add('Pace: ${(json['avg_pace'] as num).toStringAsFixed(2)} min/km');
    }
    if (json['elevation_gain'] != null) {
      details.add('Elevation: ${(json['elevation_gain'] as num).round()} m');
    }
    if (json['calories'] != null) {
      details.add('Calories: ${json['calories']} kcal');
    }

    return WorkoutCalendarEntry(
      id: json['id'] as String? ?? json['platform_activity_id'] as String,
      athleteId: json['user_id'] as String,
      workoutId: json['platform_activity_id'] as String,
      scheduledDate: DateTime(startTime.year, startTime.month, startTime.day),
      scheduledTime: TimeOfDay(hour: startTime.hour, minute: startTime.minute),
      status: 'completed', // GPS activities are always completed
      completedAt: startTime,
      actualDurationMinutes: durationMin,
      difficultyRating: null,
      painLevel: null,
      athleteNotes: details.isNotEmpty ? details.join(' • ') : null,
      reminderSent: false,
      workout: Workout(
        id: json['platform_activity_id'] as String,
        workoutName: workoutName,
        workoutType: 'cardio', // GPS activities are cardio
        exercises: [],
        estimatedDurationMinutes: durationMin,
        difficulty: 'moderate',
        equipmentNeeded: [],
      ),
    );
  }

  // Parse time from string (HH:mm:ss)
  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'athlete_id': athleteId,
      'workout_id': workoutId,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime != null
          ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'actual_duration_minutes': actualDurationMinutes,
      'difficulty_rating': difficultyRating,
      'pain_level': painLevel,
      'athlete_notes': athleteNotes,
      'reminder_sent': reminderSent,
    };
  }
}

class Workout {
  final String id;
  final String workoutName;
  final String workoutType; // rehab, strength, mobility, cardio, rest
  final List<Exercise> exercises;
  final int estimatedDurationMinutes;
  final String difficulty; // easy, moderate, hard
  final List<String> equipmentNeeded;

  Workout({
    required this.id,
    required this.workoutName,
    required this.workoutType,
    required this.exercises,
    required this.estimatedDurationMinutes,
    required this.difficulty,
    required this.equipmentNeeded,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      workoutName: json['workout_name'] as String,
      workoutType: json['workout_type'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
      difficulty: json['difficulty'] as String,
      equipmentNeeded:
          (json['equipment_needed'] as List).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_name': workoutName,
      'workout_type': workoutType,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'estimated_duration_minutes': estimatedDurationMinutes,
      'difficulty': difficulty,
      'equipment_needed': equipmentNeeded,
    };
  }
}

class Exercise {
  final String name;
  final int? sets;
  final int? reps;
  final int? durationSeconds;
  final int? restSeconds;
  final String? notes;

  Exercise({
    required this.name,
    this.sets,
    this.reps,
    this.durationSeconds,
    this.restSeconds,
    this.notes,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
      restSeconds: json['rest_seconds'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'duration_seconds': durationSeconds,
      'rest_seconds': restSeconds,
      'notes': notes,
    };
  }
}
