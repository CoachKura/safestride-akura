// Structured Workout Models (Garmin-style)
// Allows coaches to create detailed, step-by-step workouts with targets

enum WorkoutStepType {
  warmUp,
  run,
  recovery,
  rest,
  coolDown,
  repeat,
  other,
}

enum DurationType {
  distance,    // km
  time,        // seconds
  lapPress,    // Manual lap button press
  calories,    // kcal
  heartRate,   // Until target HR reached
  open,        // No limit
}

enum IntensityType {
  noTarget,
  pace,              // min/km range
  cadence,           // steps/min range
  heartRateZone,     // Zone 1-5
  customHeartRate,   // Custom bpm range
  powerZone,         // Power zone
  customPower,       // Custom watts range
}

class WorkoutStep {
  final String id;
  final WorkoutStepType stepType;
  final String? name;
  final int order;
  
  // Duration
  final DurationType durationType;
  final double? durationValue;      // km, seconds, calories, bpm
  final String? durationDisplay;    // "1.00 km", "9:40", "15 seconds"
  
  // Intensity Target
  final IntensityType intensityType;
  final double? targetMin;          // Minimum value
  final double? targetMax;          // Maximum value
  final int? heartRateZone;         // 1-5 for zone-based
  final String? targetDisplay;      // "Heart Rate Zone 2 (106-124 bpm)"
  
  // Repeat configuration
  final int? repeatCount;           // For repeat steps
  final List<String>? repeatStepIds; // IDs of steps to repeat
  
  // Notes
  final String? notes;
  final String? audioNote;          // TTS instruction

  WorkoutStep({
    required this.id,
    required this.stepType,
    this.name,
    required this.order,
    required this.durationType,
    this.durationValue,
    this.durationDisplay,
    required this.intensityType,
    this.targetMin,
    this.targetMax,
    this.heartRateZone,
    this.targetDisplay,
    this.repeatCount,
    this.repeatStepIds,
    this.notes,
    this.audioNote,
  });

  factory WorkoutStep.fromJson(Map<String, dynamic> json) {
    return WorkoutStep(
      id: json['id'] as String,
      stepType: WorkoutStepType.values.firstWhere(
        (e) => e.name == json['step_type'],
        orElse: () => WorkoutStepType.other,
      ),
      name: json['name'] as String?,
      order: json['order'] as int,
      durationType: DurationType.values.firstWhere(
        (e) => e.name == json['duration_type'],
        orElse: () => DurationType.open,
      ),
      durationValue: json['duration_value']?.toDouble(),
      durationDisplay: json['duration_display'] as String?,
      intensityType: IntensityType.values.firstWhere(
        (e) => e.name == json['intensity_type'],
        orElse: () => IntensityType.noTarget,
      ),
      targetMin: json['target_min']?.toDouble(),
      targetMax: json['target_max']?.toDouble(),
      heartRateZone: json['heart_rate_zone'] as int?,
      targetDisplay: json['target_display'] as String?,
      repeatCount: json['repeat_count'] as int?,
      repeatStepIds: json['repeat_step_ids'] != null
          ? List<String>.from(json['repeat_step_ids'])
          : null,
      notes: json['notes'] as String?,
      audioNote: json['audio_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'step_type': stepType.name,
      'name': name,
      'order': order,
      'duration_type': durationType.name,
      'duration_value': durationValue,
      'duration_display': durationDisplay,
      'intensity_type': intensityType.name,
      'target_min': targetMin,
      'target_max': targetMax,
      'heart_rate_zone': heartRateZone,
      'target_display': targetDisplay,
      'repeat_count': repeatCount,
      'repeat_step_ids': repeatStepIds,
      'notes': notes,
      'audio_note': audioNote,
    };
  }

  // Helper getters
  String get stepTypeDisplay {
    switch (stepType) {
      case WorkoutStepType.warmUp:
        return 'Warm up';
      case WorkoutStepType.run:
        return 'Run';
      case WorkoutStepType.recovery:
        return 'Recovery';
      case WorkoutStepType.rest:
        return 'Rest';
      case WorkoutStepType.coolDown:
        return 'Cool down';
      case WorkoutStepType.repeat:
        return 'Repeat';
      case WorkoutStepType.other:
        return 'Other';
    }
  }

  String get durationTypeDisplay {
    switch (durationType) {
      case DurationType.distance:
        return 'Distance';
      case DurationType.time:
        return 'Time';
      case DurationType.lapPress:
        return 'Lap Button Press';
      case DurationType.calories:
        return 'Calories';
      case DurationType.heartRate:
        return 'Heart Rate';
      case DurationType.open:
        return 'Open';
    }
  }

  String get intensityTypeDisplay {
    switch (intensityType) {
      case IntensityType.noTarget:
        return 'No Target';
      case IntensityType.pace:
        return 'Pace';
      case IntensityType.cadence:
        return 'Cadence';
      case IntensityType.heartRateZone:
        return 'Heart Rate Zone';
      case IntensityType.customHeartRate:
        return 'Custom Heart Rate';
      case IntensityType.powerZone:
        return 'Power Zone';
      case IntensityType.customPower:
        return 'Custom Power';
    }
  }

  WorkoutStep copyWith({
    String? id,
    WorkoutStepType? stepType,
    String? name,
    int? order,
    DurationType? durationType,
    double? durationValue,
    String? durationDisplay,
    IntensityType? intensityType,
    double? targetMin,
    double? targetMax,
    int? heartRateZone,
    String? targetDisplay,
    int? repeatCount,
    List<String>? repeatStepIds,
    String? notes,
    String? audioNote,
  }) {
    return WorkoutStep(
      id: id ?? this.id,
      stepType: stepType ?? this.stepType,
      name: name ?? this.name,
      order: order ?? this.order,
      durationType: durationType ?? this.durationType,
      durationValue: durationValue ?? this.durationValue,
      durationDisplay: durationDisplay ?? this.durationDisplay,
      intensityType: intensityType ?? this.intensityType,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      heartRateZone: heartRateZone ?? this.heartRateZone,
      targetDisplay: targetDisplay ?? this.targetDisplay,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatStepIds: repeatStepIds ?? this.repeatStepIds,
      notes: notes ?? this.notes,
      audioNote: audioNote ?? this.audioNote,
    );
  }
}

class StructuredWorkout {
  final String id;
  final String coachId;
  final String workoutName;
  final String? description;
  final String activityType; // Running, Cycling, etc.
  final List<WorkoutStep> steps;
  final double? estimatedDuration; // seconds
  final double? estimatedDistance; // km
  final DateTime createdAt;
  final DateTime? updatedAt;

  StructuredWorkout({
    required this.id,
    required this.coachId,
    required this.workoutName,
    this.description,
    required this.activityType,
    required this.steps,
    this.estimatedDuration,
    this.estimatedDistance,
    required this.createdAt,
    this.updatedAt,
  });

  factory StructuredWorkout.fromJson(Map<String, dynamic> json) {
    return StructuredWorkout(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      workoutName: json['workout_name'] as String,
      description: json['description'] as String?,
      activityType: json['activity_type'] as String? ?? 'Running',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((step) => WorkoutStep.fromJson(step as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedDuration: json['estimated_duration']?.toDouble(),
      estimatedDistance: json['estimated_distance']?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'workout_name': workoutName,
      'description': description,
      'activity_type': activityType,
      'steps': steps.map((step) => step.toJson()).toList(),
      'estimated_duration': estimatedDuration,
      'estimated_distance': estimatedDistance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  int get totalSteps => steps.length;

  String get estimatedTimeDisplay {
    if (estimatedDuration == null) return 'N/A';
    final hours = (estimatedDuration! / 3600).floor();
    final minutes = ((estimatedDuration! % 3600) / 60).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get estimatedDistanceDisplay {
    if (estimatedDistance == null) return 'N/A';
    return '${estimatedDistance!.toStringAsFixed(2)} km';
  }
}
