// Workout Builder Adapter for SafeStride
// Bridges WorkoutDefinition (new builder models) with Workout/WorkoutCalendarEntry (existing calendar models)

import 'package:flutter/material.dart';
import '../models/workout_builder_models.dart';
import '../models/workout_calendar_entry.dart';

class WorkoutBuilderAdapter {
  /// Convert WorkoutDefinition to Workout (for calendar system)
  static Workout toWorkout(WorkoutDefinition definition) {
    return Workout(
      id: definition.id,
      workoutName: definition.displayName,
      workoutType: _mapWorkoutType(definition.type),
      exercises: _convertToExercises(definition),
      estimatedDurationMinutes: _estimateDuration(definition),
      difficulty: _determineDifficulty(definition),
      equipmentNeeded: _determineEquipment(definition),
    );
  }

  /// Convert Workout to WorkoutCalendarEntry (scheduled workout)
  static WorkoutCalendarEntry toCalendarEntry({
    required WorkoutDefinition definition,
    required String athleteId,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
  }) {
    final workout = toWorkout(definition);

    return WorkoutCalendarEntry(
      id: definition.id,
      athleteId: athleteId,
      workoutId: workout.id,
      scheduledDate: scheduledDate ?? definition.date,
      scheduledTime: scheduledTime,
      status: 'scheduled',
      workout: workout,
    );
  }

  /// Map WorkoutType to existing workout_type string
  static String _mapWorkoutType(WorkoutType type) {
    switch (type) {
      case WorkoutType.easyRun:
        return 'easy_run';
      case WorkoutType.qualitySession:
        return 'quality_session';
      case WorkoutType.race:
        return 'race';
      case WorkoutType.crossTraining:
        return 'cross_training';
      case WorkoutType.restDay:
        return 'rest_day';
      case WorkoutType.note:
        return 'note';
    }
  }

  /// Convert WorkoutDefinition details to Exercise list
  static List<Exercise> _convertToExercises(WorkoutDefinition definition) {
    final List<Exercise> exercises = [];

    switch (definition.type) {
      case WorkoutType.easyRun:
        final easyRun = EasyRunWorkout.fromJson(definition.details);
        exercises.add(Exercise(
          name:
              'Easy Run: ${easyRun.distance} ${easyRun.distanceUnit.shortName}',
          notes: 'Maintain conversational pace',
        ));
        if (easyRun.strides != null) {
          final strides = easyRun.strides!;
          exercises.add(Exercise(
            name: 'Strides',
            sets: strides.reps,
            reps: 1,
            durationSeconds: 20, // Estimate based on distance
            restSeconds: strides.recovery.toInt(),
            notes:
                '${strides.distance}${strides.distanceUnit.shortName} @ fast pace',
          ));
        }
        break;

      case WorkoutType.qualitySession:
        final session = QualitySessionWorkout.fromJson(definition.details);

        // Warmup
        if (session.warmup > 0) {
          exercises.add(Exercise(
            name: 'Warmup',
            notes:
                '${session.warmup} ${session.warmupUnit.shortName} easy pace',
          ));
        }

        // Main sets
        for (var set in session.sets) {
          if (set is RunningSet) {
            exercises.add(Exercise(
              name: '${set.intensity.displayName} Intervals',
              sets: set.reps,
              reps: 1,
              notes: set.description,
            ));
          } else if (set is RestSet) {
            exercises.add(Exercise(
              name: 'Rest',
              restSeconds: (set.duration * 60).toInt(),
              notes: set.description,
            ));
          } else if (set is RepeatingGroup) {
            exercises.add(Exercise(
              name: 'Repeating Set',
              sets: set.repeatCount,
              reps: set.sets.length,
              notes: set.description,
            ));
          }
        }

        // Cooldown
        if (session.cooldown > 0) {
          exercises.add(Exercise(
            name: 'Cooldown',
            notes:
                '${session.cooldown} ${session.cooldownUnit.shortName} easy pace',
          ));
        }
        break;

      case WorkoutType.race:
        final race = RaceWorkout.fromJson(definition.details);
        if (race.warmup > 0) {
          exercises.add(Exercise(
            name: 'Warmup',
            notes: '${race.warmup} ${race.warmupUnit.shortName}',
          ));
        }
        exercises.add(Exercise(
          name: race.raceName,
          notes: '${race.raceDistance} ${race.raceDistanceUnit.shortName} race',
        ));
        if (race.cooldown > 0) {
          exercises.add(Exercise(
            name: 'Cooldown',
            notes: '${race.cooldown} ${race.cooldownUnit.shortName}',
          ));
        }
        break;

      case WorkoutType.crossTraining:
        final crossTraining = CrossTrainingWorkout.fromJson(definition.details);
        if (crossTraining.exercises != null) {
          for (var strengthEx in crossTraining.exercises!) {
            exercises.add(Exercise(
              name: strengthEx.name,
              sets: strengthEx.sets,
              reps: strengthEx.reps,
              notes: strengthEx.description,
            ));
          }
        } else {
          exercises.add(Exercise(
            name: crossTraining.type.displayName,
            durationSeconds: (crossTraining.duration * 60).toInt(),
            notes: '${crossTraining.intensity.displayName} intensity',
          ));
        }
        break;

      case WorkoutType.restDay:
        final restDay = RestDayWorkout.fromJson(definition.details);
        exercises.add(Exercise(
          name: 'Rest Day',
          notes: restDay.reason ?? 'Complete rest and recovery',
        ));
        break;

      case WorkoutType.note:
        exercises.add(Exercise(
          name: 'Note',
          notes: definition.coachNotes ?? 'Training note',
        ));
        break;
    }

    return exercises;
  }

  /// Estimate workout duration in minutes
  static int _estimateDuration(WorkoutDefinition definition) {
    switch (definition.type) {
      case WorkoutType.easyRun:
        final easyRun = EasyRunWorkout.fromJson(definition.details);
        // Estimate 6 min/km pace
        final runMins = (easyRun.distance * 6).round();
        final stridesMins = easyRun.strides != null ? 8 : 0;
        return runMins + stridesMins;

      case WorkoutType.qualitySession:
        final session = QualitySessionWorkout.fromJson(definition.details);
        return session.estimatedDurationMinutes;

      case WorkoutType.race:
        final race = RaceWorkout.fromJson(definition.details);
        // Race pace estimate: 4 min/km
        final raceMins = (race.raceDistance * 4).round();
        final warmupMins = (race.warmup * 6).round();
        final cooldownMins = (race.cooldown * 6).round();
        return warmupMins + raceMins + cooldownMins;

      case WorkoutType.crossTraining:
        final crossTraining = CrossTrainingWorkout.fromJson(definition.details);
        return crossTraining.duration.round();

      case WorkoutType.restDay:
        return 0;

      case WorkoutType.note:
        return 0;
    }
  }

  /// Determine workout difficulty
  static String _determineDifficulty(WorkoutDefinition definition) {
    switch (definition.type) {
      case WorkoutType.easyRun:
        return 'easy';

      case WorkoutType.qualitySession:
        final session = QualitySessionWorkout.fromJson(definition.details);
        // Check intensity of sets
        bool hasHardSets = false;
        for (var set in session.sets) {
          if (set is RunningSet) {
            if (set.intensity == WorkoutIntensity.interval ||
                set.intensity == WorkoutIntensity.repetition ||
                set.intensity == WorkoutIntensity.fastReps) {
              hasHardSets = true;
              break;
            }
          }
        }
        return hasHardSets ? 'hard' : 'moderate';

      case WorkoutType.race:
        return 'hard';

      case WorkoutType.crossTraining:
        final crossTraining = CrossTrainingWorkout.fromJson(definition.details);
        switch (crossTraining.intensity) {
          case WorkoutIntensity.easy:
          case WorkoutIntensity.recovery:
            return 'easy';
          case WorkoutIntensity.threshold:
          case WorkoutIntensity.marathon:
            return 'moderate';
          default:
            return 'hard';
        }

      case WorkoutType.restDay:
        return 'easy';

      case WorkoutType.note:
        return 'easy';
    }
  }

  /// Determine required equipment
  static List<String> _determineEquipment(WorkoutDefinition definition) {
    final List<String> equipment = [];

    switch (definition.type) {
      case WorkoutType.easyRun:
      case WorkoutType.qualitySession:
      case WorkoutType.race:
        equipment.addAll(['running_shoes', 'watch']);
        break;

      case WorkoutType.crossTraining:
        final crossTraining = CrossTrainingWorkout.fromJson(definition.details);
        switch (crossTraining.type) {
          case CrossTrainingType.strength:
            equipment.addAll(['mat', 'dumbbells', 'resistance_band']);
            break;
          case CrossTrainingType.yoga:
            equipment.add('mat');
            break;
          case CrossTrainingType.cycling:
            equipment.add('bike');
            break;
          case CrossTrainingType.swimming:
            equipment.addAll(['pool_access', 'goggles']);
            break;
          case CrossTrainingType.rowing:
            equipment.add('rowing_machine');
            break;
          case CrossTrainingType.elliptical:
            equipment.add('elliptical_machine');
            break;
        }
        break;

      case WorkoutType.restDay:
      case WorkoutType.note:
        equipment.add('none');
        break;
    }

    return equipment;
  }

  /// Create WorkoutDefinition from existing Workout (reverse conversion)
  static WorkoutDefinition fromWorkout(Workout workout, DateTime date) {
    WorkoutType type = WorkoutType.note;
    Map<String, dynamic> details = {};

    // Map workout_type back to WorkoutType
    switch (workout.workoutType) {
      case 'easy_run':
        type = WorkoutType.easyRun;
        details = EasyRunWorkout(
          distance: 10.0, // Default, would need actual data
          distanceUnit: WorkoutUnit.kilometers,
        ).toJson();
        break;
      case 'quality_session':
        type = WorkoutType.qualitySession;
        break;
      case 'race':
        type = WorkoutType.race;
        break;
      case 'cross_training':
        type = WorkoutType.crossTraining;
        break;
      case 'rest_day':
        type = WorkoutType.restDay;
        break;
      default:
        type = WorkoutType.note;
    }

    return WorkoutDefinition(
      id: workout.id,
      type: type,
      date: date,
      customName: workout.workoutName,
      details: details,
    );
  }

  /// Helper: Generate workout description for display
  static String generateDescription(WorkoutDefinition definition) {
    switch (definition.type) {
      case WorkoutType.easyRun:
        final easyRun = EasyRunWorkout.fromJson(definition.details);
        String desc =
            '${easyRun.distance} ${easyRun.distanceUnit.shortName} easy run';
        if (easyRun.strides != null) {
          desc +=
              ' + ${easyRun.strides!.reps} x ${easyRun.strides!.distance}${easyRun.strides!.distanceUnit.shortName} strides';
        }
        return desc;

      case WorkoutType.qualitySession:
        final session = QualitySessionWorkout.fromJson(definition.details);
        return '${session.totalDistance.toStringAsFixed(1)} km total (${session.estimatedDurationMinutes} min)';

      case WorkoutType.race:
        final race = RaceWorkout.fromJson(definition.details);
        return '${race.raceName} - ${race.raceDistance} ${race.raceDistanceUnit.shortName}';

      case WorkoutType.crossTraining:
        final crossTraining = CrossTrainingWorkout.fromJson(definition.details);
        return '${crossTraining.type.displayName} (${crossTraining.duration.round()} ${crossTraining.durationUnit.shortName})';

      case WorkoutType.restDay:
        final restDay = RestDayWorkout.fromJson(definition.details);
        return restDay.reason ?? 'Rest day';

      case WorkoutType.note:
        return definition.coachNotes ?? 'Training note';
    }
  }
}
