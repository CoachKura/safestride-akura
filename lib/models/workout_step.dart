// Workout Step Model
// Represents individual steps in a structured workout (warm-up, run, intervals, cool-down)

import 'package:flutter/material.dart';

enum StepType {
  warmUp,
  run,
  walk,
  interval,
  recovery,
  coolDown,
  rest,
  repeat,
}

enum StepTarget {
  open, // Lap button press
  distance, // Target distance
  duration, // Target time
  heartRate, // Target HR zone
  pace, // Target pace
  calories, // Target calories
}

class WorkoutStep {
  final String id;
  final StepType type;
  final StepTarget target;
  final double? targetValue; // Distance in meters, duration in seconds, etc.
  final String? targetUnit; // 'km', 'mi', 'min', 'sec', etc.
  final double? targetPaceMin; // Min pace (min/km)
  final double? targetPaceMax; // Max pace (min/km)
  final int? targetHRZone; // HR zone 1-5
  final int? repeatCount; // For repeat steps
  final List<WorkoutStep>? repeatSteps; // Steps to repeat
  final String? notes;
  final int order;

  WorkoutStep({
    String? id,
    required this.type,
    this.target = StepTarget.open,
    this.targetValue,
    this.targetUnit,
    this.targetPaceMin,
    this.targetPaceMax,
    this.targetHRZone,
    this.repeatCount,
    this.repeatSteps,
    this.notes,
    this.order = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Get display name for step type
  String get typeName {
    switch (type) {
      case StepType.warmUp:
        return 'Warm up';
      case StepType.run:
        return 'Run';
      case StepType.walk:
        return 'Walk';
      case StepType.interval:
        return 'Interval';
      case StepType.recovery:
        return 'Recovery';
      case StepType.coolDown:
        return 'Cool down';
      case StepType.rest:
        return 'Rest';
      case StepType.repeat:
        return 'Repeat';
    }
  }

  // Get color for step type
  Color get typeColor {
    switch (type) {
      case StepType.warmUp:
        return Colors.red;
      case StepType.run:
        return Colors.blue;
      case StepType.walk:
        return Colors.orange;
      case StepType.interval:
        return Colors.purple;
      case StepType.recovery:
        return Colors.green;
      case StepType.coolDown:
        return Colors.teal;
      case StepType.rest:
        return Colors.grey;
      case StepType.repeat:
        return Colors.amber;
    }
  }

  // Get icon for step type
  IconData get typeIcon {
    switch (type) {
      case StepType.warmUp:
        return Icons.whatshot;
      case StepType.run:
        return Icons.directions_run;
      case StepType.walk:
        return Icons.directions_walk;
      case StepType.interval:
        return Icons.flash_on;
      case StepType.recovery:
        return Icons.healing;
      case StepType.coolDown:
        return Icons.ac_unit;
      case StepType.rest:
        return Icons.pause;
      case StepType.repeat:
        return Icons.repeat;
    }
  }

  // Get target description
  String get targetDescription {
    switch (target) {
      case StepTarget.open:
        return 'Lap Button Press';
      case StepTarget.distance:
        if (targetValue == null) return 'Distance';
        final km = targetValue! / 1000;
        final mi = targetValue! / 1609.34;
        if (targetUnit == 'mi') {
          return '${mi.toStringAsFixed(2)} mi';
        }
        return '${km.toStringAsFixed(2)} km';
      case StepTarget.duration:
        if (targetValue == null) return 'Duration';
        final minutes = (targetValue! / 60).floor();
        final seconds = (targetValue! % 60).floor();
        if (minutes > 0 && seconds > 0) {
          return '$minutes:${seconds.toString().padLeft(2, '0')}';
        } else if (minutes > 0) {
          return '$minutes min';
        }
        return '$seconds sec';
      case StepTarget.heartRate:
        return targetHRZone != null ? 'HR Zone $targetHRZone' : 'Heart Rate';
      case StepTarget.pace:
        if (targetPaceMin != null && targetPaceMax != null) {
          return '${_formatPace(targetPaceMin!)} - ${_formatPace(targetPaceMax!)} /km';
        }
        return 'Pace';
      case StepTarget.calories:
        return targetValue != null ? '${targetValue!.toInt()} cal' : 'Calories';
    }
  }

  String _formatPace(double pace) {
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Get estimated time for this step
  Duration get estimatedDuration {
    switch (target) {
      case StepTarget.duration:
        return Duration(seconds: targetValue?.toInt() ?? 0);
      case StepTarget.distance:
        // Estimate based on average pace (6:00/km = 360 sec/km)
        final avgPace = (targetPaceMin ?? 6) +
            ((targetPaceMax ?? 6) - (targetPaceMin ?? 6)) / 2;
        final distanceKm = (targetValue ?? 0) / 1000;
        return Duration(seconds: (distanceKm * avgPace * 60).toInt());
      default:
        return const Duration(minutes: 5); // Default estimate
    }
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'target': target.index,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'targetPaceMin': targetPaceMin,
      'targetPaceMax': targetPaceMax,
      'targetHRZone': targetHRZone,
      'repeatCount': repeatCount,
      'repeatSteps': repeatSteps?.map((s) => s.toJson()).toList(),
      'notes': notes,
      'order': order,
    };
  }

  // Create from JSON
  factory WorkoutStep.fromJson(Map<String, dynamic> json) {
    return WorkoutStep(
      id: json['id'],
      type: StepType.values[json['type'] ?? 0],
      target: StepTarget.values[json['target'] ?? 0],
      targetValue: json['targetValue']?.toDouble(),
      targetUnit: json['targetUnit'],
      targetPaceMin: json['targetPaceMin']?.toDouble(),
      targetPaceMax: json['targetPaceMax']?.toDouble(),
      targetHRZone: json['targetHRZone'],
      repeatCount: json['repeatCount'],
      repeatSteps: json['repeatSteps'] != null
          ? (json['repeatSteps'] as List)
              .map((s) => WorkoutStep.fromJson(s))
              .toList()
          : null,
      notes: json['notes'],
      order: json['order'] ?? 0,
    );
  }

  // Create a copy with modifications
  WorkoutStep copyWith({
    String? id,
    StepType? type,
    StepTarget? target,
    double? targetValue,
    String? targetUnit,
    double? targetPaceMin,
    double? targetPaceMax,
    int? targetHRZone,
    int? repeatCount,
    List<WorkoutStep>? repeatSteps,
    String? notes,
    int? order,
  }) {
    return WorkoutStep(
      id: id ?? this.id,
      type: type ?? this.type,
      target: target ?? this.target,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      targetPaceMin: targetPaceMin ?? this.targetPaceMin,
      targetPaceMax: targetPaceMax ?? this.targetPaceMax,
      targetHRZone: targetHRZone ?? this.targetHRZone,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatSteps: repeatSteps ?? this.repeatSteps,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }
}

/// Structured Workout Model
class StructuredWorkout {
  final String id;
  final String name;
  final String? description;
  final String activityType; // 'run', 'walk', 'bike', etc.
  final List<WorkoutStep> steps;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final String? notes;
  final bool isTemplate;
  final String? athleteId;

  StructuredWorkout({
    String? id,
    required this.name,
    this.description,
    this.activityType = 'run',
    required this.steps,
    DateTime? createdAt,
    this.scheduledDate,
    this.notes,
    this.isTemplate = false,
    this.athleteId,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  // Get total estimated duration
  Duration get totalEstimatedDuration {
    return steps.fold(
        Duration.zero, (total, step) => total + step.estimatedDuration);
  }

  // Get total distance (if applicable)
  double? get totalDistance {
    double total = 0;
    for (final step in steps) {
      if (step.target == StepTarget.distance && step.targetValue != null) {
        total += step.targetValue!;
      }
    }
    return total > 0 ? total : null;
  }

  // Format estimated time
  String get estimatedTimeDisplay {
    final duration = totalEstimatedDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '$seconds sec';
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'activityType': activityType,
      'steps': steps.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'notes': notes,
      'isTemplate': isTemplate,
      'athleteId': athleteId,
    };
  }

  // Create from JSON
  factory StructuredWorkout.fromJson(Map<String, dynamic> json) {
    return StructuredWorkout(
      id: json['id'],
      name: json['name'] ?? 'Workout',
      description: json['description'],
      activityType: json['activityType'] ?? 'run',
      steps: (json['steps'] as List?)
              ?.map((s) => WorkoutStep.fromJson(s))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'])
          : null,
      notes: json['notes'],
      isTemplate: json['isTemplate'] ?? false,
      athleteId: json['athleteId'],
    );
  }

  // Create a copy with modifications
  StructuredWorkout copyWith({
    String? id,
    String? name,
    String? description,
    String? activityType,
    List<WorkoutStep>? steps,
    DateTime? createdAt,
    DateTime? scheduledDate,
    String? notes,
    bool? isTemplate,
    String? athleteId,
  }) {
    return StructuredWorkout(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      activityType: activityType ?? this.activityType,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      notes: notes ?? this.notes,
      isTemplate: isTemplate ?? this.isTemplate,
      athleteId: athleteId ?? this.athleteId,
    );
  }
}
