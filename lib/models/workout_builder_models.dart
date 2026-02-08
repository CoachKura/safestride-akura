import 'package:flutter/material.dart';

enum WorkoutType {
  easyRun,
  qualitySession,
  race,
  crossTraining,
  restDay,
  note;

  IconData get icon {
    switch (this) {
      case WorkoutType.easyRun:
        return Icons.directions_run;
      case WorkoutType.qualitySession:
        return Icons.speed;
      case WorkoutType.race:
        return Icons.emoji_events;
      case WorkoutType.crossTraining:
        return Icons.fitness_center;
      case WorkoutType.restDay:
        return Icons.hotel;
      case WorkoutType.note:
        return Icons.note;
    }
  }

  String get displayName {
    switch (this) {
      case WorkoutType.easyRun:
        return 'Easy Run';
      case WorkoutType.qualitySession:
        return 'Quality Session';
      case WorkoutType.race:
        return 'Race';
      case WorkoutType.crossTraining:
        return 'Cross Training';
      case WorkoutType.restDay:
        return 'Rest Day';
      case WorkoutType.note:
        return 'Note';
    }
  }
}

enum WorkoutUnit {
  kilometers,
  miles,
  meters,
  minutes,
  hours,
  seconds;

  String get shortName {
    switch (this) {
      case WorkoutUnit.kilometers:
        return 'km';
      case WorkoutUnit.miles:
        return 'mi';
      case WorkoutUnit.meters:
        return 'm';
      case WorkoutUnit.minutes:
        return 'min';
      case WorkoutUnit.hours:
        return 'hr';
      case WorkoutUnit.seconds:
        return 'sec';
    }
  }
}

enum RecoveryUnit {
  secondsWalk,
  minutesWalk,
  secondsJog,
  minutesJog;

  String get displayName {
    switch (this) {
      case RecoveryUnit.secondsWalk:
        return 'seconds walk';
      case RecoveryUnit.minutesWalk:
        return 'minutes walk';
      case RecoveryUnit.secondsJog:
        return 'seconds jog';
      case RecoveryUnit.minutesJog:
        return 'minutes jog';
    }
  }
}

enum CrossTrainingType {
  strength,
  yoga,
  cycling,
  swimming,
  rowing,
  elliptical;

  IconData get icon {
    switch (this) {
      case CrossTrainingType.strength:
        return Icons.fitness_center;
      case CrossTrainingType.yoga:
        return Icons.self_improvement;
      case CrossTrainingType.cycling:
        return Icons.directions_bike;
      case CrossTrainingType.swimming:
        return Icons.pool;
      case CrossTrainingType.rowing:
        return Icons.rowing;
      case CrossTrainingType.elliptical:
        return Icons.directions_walk;
    }
  }

  String get displayName {
    switch (this) {
      case CrossTrainingType.strength:
        return 'Strength Training';
      case CrossTrainingType.yoga:
        return 'Yoga';
      case CrossTrainingType.cycling:
        return 'Cycling';
      case CrossTrainingType.swimming:
        return 'Swimming';
      case CrossTrainingType.rowing:
        return 'Rowing';
      case CrossTrainingType.elliptical:
        return 'Elliptical';
    }
  }
}

enum WorkoutIntensity {
  easy,
  recovery,
  marathon,
  threshold,
  interval,
  repetition,
  fastReps;

  String get displayName {
    switch (this) {
      case WorkoutIntensity.easy:
        return 'Easy';
      case WorkoutIntensity.recovery:
        return 'Recovery';
      case WorkoutIntensity.marathon:
        return 'Marathon';
      case WorkoutIntensity.threshold:
        return 'Threshold';
      case WorkoutIntensity.interval:
        return 'Interval';
      case WorkoutIntensity.repetition:
        return 'Repetition';
      case WorkoutIntensity.fastReps:
        return 'Fast Reps';
    }
  }
}

class WorkoutDefinition {
  final String id;
  final WorkoutType type;
  final DateTime date;
  final String? customName;
  final dynamic details;
  final String? coachNotes;

  WorkoutDefinition({
    required this.id,
    required this.type,
    required this.date,
    this.customName,
    this.details,
    this.coachNotes,
  });

  String get displayName {
    if (customName != null && customName!.isNotEmpty) {
      return customName!;
    }
    return type.displayName;
  }
}

class StridesSet {
  final int reps;
  final double distance;
  final WorkoutUnit distanceUnit;
  final double recovery;
  final RecoveryUnit recoveryUnit;

  StridesSet({
    required this.reps,
    required this.distance,
    required this.distanceUnit,
    required this.recovery,
    required this.recoveryUnit,
  });

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'distance': distance,
        'distanceUnit': distanceUnit.name,
        'recovery': recovery,
        'recoveryUnit': recoveryUnit.name,
      };

  factory StridesSet.fromJson(Map<String, dynamic> json) => StridesSet(
        reps: json['reps'] as int,
        distance: (json['distance'] as num).toDouble(),
        distanceUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['distanceUnit'],
        ),
        recovery: (json['recovery'] as num).toDouble(),
        recoveryUnit: RecoveryUnit.values.firstWhere(
          (e) => e.name == json['recoveryUnit'],
        ),
      );
}

class EasyRunWorkout {
  final double distance;
  final WorkoutUnit distanceUnit;
  final StridesSet? strides;

  EasyRunWorkout({
    required this.distance,
    required this.distanceUnit,
    this.strides,
  });

  Map<String, dynamic> toJson() => {
        'distance': distance,
        'distanceUnit': distanceUnit.name,
        'strides': strides?.toJson(),
      };

  factory EasyRunWorkout.fromJson(Map<String, dynamic> json) => EasyRunWorkout(
        distance: (json['distance'] as num).toDouble(),
        distanceUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['distanceUnit'],
        ),
        strides: json['strides'] != null
            ? StridesSet.fromJson(json['strides'] as Map<String, dynamic>)
            : null,
      );
}

abstract class WorkoutSet {
  Map<String, dynamic> toJson();
  String get description;
}

class RunningSet extends WorkoutSet {
  final int reps;
  final double distance;
  final WorkoutUnit distanceUnit;
  final WorkoutIntensity intensity;
  final double recovery;
  final RecoveryUnit recoveryUnit;

  RunningSet({
    required this.reps,
    required this.distance,
    required this.distanceUnit,
    required this.intensity,
    required this.recovery,
    required this.recoveryUnit,
  });

  @override
  String get description {
    return ' @  (  recovery)';
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'running',
        'reps': reps,
        'distance': distance,
        'distanceUnit': distanceUnit.name,
        'intensity': intensity.name,
        'recovery': recovery,
        'recoveryUnit': recoveryUnit.name,
      };

  factory RunningSet.fromJson(Map<String, dynamic> json) => RunningSet(
        reps: json['reps'] as int,
        distance: (json['distance'] as num).toDouble(),
        distanceUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['distanceUnit'],
        ),
        intensity: WorkoutIntensity.values.firstWhere(
          (e) => e.name == json['intensity'],
        ),
        recovery: (json['recovery'] as num).toDouble(),
        recoveryUnit: RecoveryUnit.values.firstWhere(
          (e) => e.name == json['recoveryUnit'],
        ),
      );
}

class RestSet extends WorkoutSet {
  final double duration;
  final WorkoutUnit unit;

  RestSet({
    required this.duration,
    required this.unit,
  });

  @override
  String get description => 'Rest:  ';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rest',
        'duration': duration,
        'unit': unit.name,
      };

  factory RestSet.fromJson(Map<String, dynamic> json) => RestSet(
        duration: (json['duration'] as num).toDouble(),
        unit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['unit'],
        ),
      );
}

class RepeatingGroup extends WorkoutSet {
  final int repeatCount;
  final List<WorkoutSet> sets;

  RepeatingGroup({
    required this.repeatCount,
    required this.sets,
  });

  @override
  String get description {
    return ' x ()';
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'repeating',
        'repeatCount': repeatCount,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory RepeatingGroup.fromJson(Map<String, dynamic> json) => RepeatingGroup(
        repeatCount: json['repeatCount'] as int,
        sets: (json['sets'] as List)
            .map((s) => _workoutSetFromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

WorkoutSet _workoutSetFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'running':
      return RunningSet.fromJson(json);
    case 'rest':
      return RestSet.fromJson(json);
    case 'repeating':
      return RepeatingGroup.fromJson(json);
    default:
      throw Exception('Unknown workout set type: ');
  }
}

class QualitySessionWorkout {
  final double warmup;
  final WorkoutUnit warmupUnit;
  final List<WorkoutSet> sets;
  final double cooldown;
  final WorkoutUnit cooldownUnit;

  QualitySessionWorkout({
    required this.warmup,
    required this.warmupUnit,
    required this.sets,
    required this.cooldown,
    required this.cooldownUnit,
  });

  double get totalDistance {
    double total = 0.0;

    // Add warmup
    if (warmupUnit == WorkoutUnit.kilometers ||
        warmupUnit == WorkoutUnit.miles ||
        warmupUnit == WorkoutUnit.meters) {
      total += warmup;
    }

    // Add cooldown
    if (cooldownUnit == WorkoutUnit.kilometers ||
        cooldownUnit == WorkoutUnit.miles ||
        cooldownUnit == WorkoutUnit.meters) {
      total += cooldown;
    }

    // Add sets
    for (var set in sets) {
      total += _calculateSetDistance(set);
    }

    return total;
  }

  double _calculateSetDistance(WorkoutSet set) {
    if (set is RunningSet) {
      return set.distance * set.reps;
    } else if (set is RepeatingGroup) {
      double groupDistance = 0.0;
      for (var innerSet in set.sets) {
        groupDistance += _calculateSetDistance(innerSet);
      }
      return groupDistance * set.repeatCount;
    }
    return 0.0;
  }

  int get estimatedDurationMinutes {
    // Rough estimation: warmup + cooldown + sets
    int minutes = 0;

    // Warmup
    if (warmupUnit == WorkoutUnit.minutes) {
      minutes += warmup.toInt();
    } else if (warmupUnit == WorkoutUnit.kilometers) {
      minutes += (warmup * 6).toInt(); // Assume 6 min/km
    }

    // Cooldown
    if (cooldownUnit == WorkoutUnit.minutes) {
      minutes += cooldown.toInt();
    } else if (cooldownUnit == WorkoutUnit.kilometers) {
      minutes += (cooldown * 6).toInt();
    }

    // Estimate sets at 20-30 minutes depending on intensity
    minutes += sets.length * 5;

    return minutes;
  }

  Map<String, dynamic> toJson() => {
        'warmup': warmup,
        'warmupUnit': warmupUnit.name,
        'sets': sets.map((s) => s.toJson()).toList(),
        'cooldown': cooldown,
        'cooldownUnit': cooldownUnit.name,
      };

  factory QualitySessionWorkout.fromJson(Map<String, dynamic> json) =>
      QualitySessionWorkout(
        warmup: (json['warmup'] as num).toDouble(),
        warmupUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['warmupUnit'],
        ),
        sets: (json['sets'] as List)
            .map((s) => _workoutSetFromJson(s as Map<String, dynamic>))
            .toList(),
        cooldown: (json['cooldown'] as num).toDouble(),
        cooldownUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['cooldownUnit'],
        ),
      );
}

class RaceWorkout {
  final double warmup;
  final WorkoutUnit warmupUnit;
  final String raceName;
  final double raceDistance;
  final WorkoutUnit raceDistanceUnit;
  final double cooldown;
  final WorkoutUnit cooldownUnit;

  RaceWorkout({
    required this.warmup,
    required this.warmupUnit,
    required this.raceName,
    required this.raceDistance,
    required this.raceDistanceUnit,
    required this.cooldown,
    required this.cooldownUnit,
  });

  Map<String, dynamic> toJson() => {
        'warmup': warmup,
        'warmupUnit': warmupUnit.name,
        'raceName': raceName,
        'raceDistance': raceDistance,
        'raceDistanceUnit': raceDistanceUnit.name,
        'cooldown': cooldown,
        'cooldownUnit': cooldownUnit.name,
      };

  factory RaceWorkout.fromJson(Map<String, dynamic> json) => RaceWorkout(
        warmup: (json['warmup'] as num).toDouble(),
        warmupUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['warmupUnit'],
        ),
        raceName: json['raceName'] as String,
        raceDistance: (json['raceDistance'] as num).toDouble(),
        raceDistanceUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['raceDistanceUnit'],
        ),
        cooldown: (json['cooldown'] as num).toDouble(),
        cooldownUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['cooldownUnit'],
        ),
      );
}

class StrengthExercise {
  final String name;
  final int sets;
  final int reps;
  final double? weight;
  final String? unit;
  final String? description;

  StrengthExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.unit,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'unit': unit,
        'description': description,
      };

  factory StrengthExercise.fromJson(Map<String, dynamic> json) =>
      StrengthExercise(
        name: json['name'] as String,
        sets: json['sets'] as int,
        reps: json['reps'] as int,
        weight:
            json['weight'] != null ? (json['weight'] as num).toDouble() : null,
        unit: json['unit'] as String?,
        description: json['description'] as String?,
      );
}

class CrossTrainingWorkout {
  final CrossTrainingType type;
  final double duration;
  final WorkoutUnit durationUnit;
  final WorkoutIntensity intensity;
  final List<StrengthExercise>? exercises;

  CrossTrainingWorkout({
    required this.type,
    required this.duration,
    required this.durationUnit,
    required this.intensity,
    this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'duration': duration,
        'durationUnit': durationUnit.name,
        'intensity': intensity.name,
        'exercises': exercises?.map((e) => e.toJson()).toList(),
      };

  factory CrossTrainingWorkout.fromJson(Map<String, dynamic> json) =>
      CrossTrainingWorkout(
        type: CrossTrainingType.values.firstWhere(
          (e) => e.name == json['type'],
        ),
        duration: (json['duration'] as num).toDouble(),
        durationUnit: WorkoutUnit.values.firstWhere(
          (e) => e.name == json['durationUnit'],
        ),
        intensity: WorkoutIntensity.values.firstWhere(
          (e) => e.name == json['intensity'],
        ),
        exercises: json['exercises'] != null
            ? (json['exercises'] as List)
                .map(
                    (e) => StrengthExercise.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
      );
}

class RestDayWorkout {
  final String? reason;

  RestDayWorkout({this.reason});

  Map<String, dynamic> toJson() => {
        'reason': reason,
      };

  factory RestDayWorkout.fromJson(Map<String, dynamic> json) => RestDayWorkout(
        reason: json['reason'] as String?,
      );
}
