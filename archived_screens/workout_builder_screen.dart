// Workout Builder Screen for SafeStride
// Allows coaches/athletes to create custom workouts

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_builder_models.dart';
import '../services/workout_builder_adapter.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? athleteId;

  const WorkoutBuilderScreen({
    super.key,
    this.initialDate,
    this.athleteId,
  });

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  WorkoutType _selectedType = WorkoutType.easyRun;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  // Common fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Easy Run fields
  final TextEditingController _distanceController = TextEditingController();
  WorkoutUnit _distanceUnit = WorkoutUnit.kilometers;
  bool _includeStrides = false;

  // Strides fields
  final TextEditingController _stridesRepsController =
      TextEditingController(text: '6');
  final TextEditingController _stridesDistanceController =
      TextEditingController(text: '100');
  WorkoutUnit _stridesDistanceUnit = WorkoutUnit.meters;
  final TextEditingController _stridesRecoveryController =
      TextEditingController(text: '90');
  RecoveryUnit _stridesRecoveryUnit = RecoveryUnit.secondsWalk;

  // Quality Session fields
  final TextEditingController _warmupController = TextEditingController();
  final TextEditingController _cooldownController = TextEditingController();
  WorkoutUnit _warmupUnit = WorkoutUnit.kilometers;
  WorkoutUnit _cooldownUnit = WorkoutUnit.kilometers;
  final List<WorkoutSet> _sets = [];

  // Race fields
  final TextEditingController _raceNameController = TextEditingController();
  final TextEditingController _raceDistanceController = TextEditingController();
  WorkoutUnit _raceDistanceUnit = WorkoutUnit.kilometers;

  // Cross Training fields
  CrossTrainingType _crossTrainingType = CrossTrainingType.strength;
  final TextEditingController _durationController = TextEditingController();
  WorkoutUnit _durationUnit = WorkoutUnit.minutes;
  WorkoutIntensity _intensity = WorkoutIntensity.easy;
  final List<StrengthExercise> _strengthExercises = [];

  // Rest Day fields
  final TextEditingController _restReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workout'),
        actions: [
          TextButton(
            onPressed: _saveWorkout,
            child: const Text(
              'SAVE',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkoutTypeSelector(),
            const SizedBox(height: 24),
            _buildCommonFields(),
            const SizedBox(height: 24),
            _buildTypeSpecificFields(),
            const SizedBox(height: 80),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildWorkoutTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WorkoutType.values.map((type) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type.icon),
                      const SizedBox(width: 4),
                      Text(type.displayName),
                    ],
                  ),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Custom Name (optional)',
                hintText: 'e.g., Monday Morning Run',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
              onTap: _selectDate,
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              subtitle: Text(_selectedTime.format(context)),
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Coach Notes',
                hintText: 'Instructions or tips for this workout...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
      case WorkoutType.easyRun:
        return _buildEasyRunFields();
      case WorkoutType.qualitySession:
        return _buildQualitySessionFields();
      case WorkoutType.race:
        return _buildRaceFields();
      case WorkoutType.crossTraining:
        return _buildCrossTrainingFields();
      case WorkoutType.restDay:
        return _buildRestDayFields();
      case WorkoutType.note:
        return _buildNoteFields();
    }
  }

  Widget _buildEasyRunFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Easy Run Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _distanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Distance',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<WorkoutUnit>(
                  value: _distanceUnit,
                  items: [WorkoutUnit.kilometers, WorkoutUnit.miles]
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.shortName),
                          ))
                      .toList(),
                  onChanged: (unit) {
                    if (unit != null) {
                      setState(() => _distanceUnit = unit);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Include Strides'),
              value: _includeStrides,
              onChanged: (value) =>
                  setState(() => _includeStrides = value ?? false),
            ),
            if (_includeStrides) ...[
              const Divider(),
              const Text(
                'Strides Setup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stridesRepsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _stridesDistanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Distance'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<WorkoutUnit>(
                    value: _stridesDistanceUnit,
                    items: [WorkoutUnit.meters, WorkoutUnit.kilometers]
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit.shortName),
                            ))
                        .toList(),
                    onChanged: (unit) {
                      if (unit != null) {
                        setState(() => _stridesDistanceUnit = unit);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stridesRecoveryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Recovery'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<RecoveryUnit>(
                      value: _stridesRecoveryUnit,
                      isExpanded: true,
                      items: [
                        RecoveryUnit.secondsWalk,
                        RecoveryUnit.minutesWalk,
                        RecoveryUnit.secondsJog,
                        RecoveryUnit.minutesJog,
                      ]
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit.displayName),
                              ))
                          .toList(),
                      onChanged: (unit) {
                        if (unit != null) {
                          setState(() => _stridesRecoveryUnit = unit);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySessionFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quality Session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _warmupController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Warmup'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<WorkoutUnit>(
                  value: _warmupUnit,
                  items: [
                    WorkoutUnit.kilometers,
                    WorkoutUnit.miles,
                    WorkoutUnit.minutes
                  ]
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.shortName),
                          ))
                      .toList(),
                  onChanged: (unit) {
                    if (unit != null) {
                      setState(() => _warmupUnit = unit);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Main Sets',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_sets.isEmpty)
              Center(
                child: Text(
                  'No sets added yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  String description = '';
                  if (set is RunningSet) {
                    description = set.description;
                  } else if (set is RestSet) {
                    description = set.description;
                  }
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(description),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => setState(() => _sets.removeAt(index)),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addSet,
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cooldownController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cooldown'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<WorkoutUnit>(
                  value: _cooldownUnit,
                  items: [
                    WorkoutUnit.kilometers,
                    WorkoutUnit.miles,
                    WorkoutUnit.minutes
                  ]
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.shortName),
                          ))
                      .toList(),
                  onChanged: (unit) {
                    if (unit != null) {
                      setState(() => _cooldownUnit = unit);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRaceFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Race Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _raceNameController,
              decoration: const InputDecoration(
                labelText: 'Race Name',
                hintText: 'e.g., 5K City Championship',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _raceDistanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Distance'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<WorkoutUnit>(
                  value: _raceDistanceUnit,
                  items: [WorkoutUnit.kilometers, WorkoutUnit.miles]
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.shortName),
                          ))
                      .toList(),
                  onChanged: (unit) {
                    if (unit != null) {
                      setState(() => _raceDistanceUnit = unit);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _warmupController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Warmup'),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('km'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cooldownController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cooldown'),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('km'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossTrainingFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cross Training',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CrossTrainingType>(
              initialValue: _crossTrainingType,
              decoration: const InputDecoration(labelText: 'Activity'),
              items: CrossTrainingType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (type) {
                if (type != null) {
                  setState(() => _crossTrainingType = type);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Duration'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<WorkoutUnit>(
                  value: _durationUnit,
                  items: [WorkoutUnit.minutes, WorkoutUnit.hours]
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.shortName),
                          ))
                      .toList(),
                  onChanged: (unit) {
                    if (unit != null) {
                      setState(() => _durationUnit = unit);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WorkoutIntensity>(
              initialValue: _intensity,
              decoration: const InputDecoration(labelText: 'Intensity'),
              items: [
                WorkoutIntensity.easy,
                WorkoutIntensity.recovery,
                WorkoutIntensity.marathon,
                WorkoutIntensity.threshold,
              ]
                  .map((intensity) => DropdownMenuItem(
                        value: intensity,
                        child: Text(intensity.displayName),
                      ))
                  .toList(),
              onChanged: (intensity) {
                if (intensity != null) {
                  setState(() => _intensity = intensity);
                }
              },
            ),
            if (_crossTrainingType == CrossTrainingType.strength) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Exercises',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_strengthExercises.isEmpty)
                Center(
                  child: Text(
                    'No exercises added',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _strengthExercises.length,
                  itemBuilder: (context, index) {
                    final ex = _strengthExercises[index];
                    return ListTile(
                      title: Text(ex.name),
                      subtitle: Text(ex.description ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            setState(() => _strengthExercises.removeAt(index)),
                      ),
                    );
                  },
                ),
              OutlinedButton.icon(
                onPressed: _addStrengthExercise,
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rest Day',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restReasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Recovery, Injury, Travel',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training Note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Use the Coach Notes field above to add your note',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addSet() {
    // Show dialog to add a running set or rest set
    showDialog(
      context: context,
      builder: (context) => _AddSetDialog(
        onSetAdded: (set) {
          setState(() => _sets.add(set));
        },
      ),
    );
  }

  void _addStrengthExercise() {
    showDialog(
      context: context,
      builder: (context) => _AddStrengthExerciseDialog(
        onExerciseAdded: (exercise) {
          setState(() => _strengthExercises.add(exercise));
        },
      ),
    );
  }

  void _saveWorkout() {
    try {
      final workoutDef = _buildWorkoutDefinition();

      // Convert to calendar entry
      WorkoutBuilderAdapter.toCalendarEntry(
        definition: workoutDef,
        athleteId: widget.athleteId ?? 'mock-athlete',
        scheduledDate: _selectedDate,
        scheduledTime: _selectedTime,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout created successfully! '),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, workoutDef);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  WorkoutDefinition _buildWorkoutDefinition() {
    Map<String, dynamic> details = {};

    switch (_selectedType) {
      case WorkoutType.easyRun:
        final distance = double.tryParse(_distanceController.text) ?? 10.0;
        StridesSet? strides;
        if (_includeStrides) {
          strides = StridesSet(
            reps: int.tryParse(_stridesRepsController.text) ?? 6,
            distance: double.tryParse(_stridesDistanceController.text) ?? 100,
            distanceUnit: _stridesDistanceUnit,
            recovery: double.tryParse(_stridesRecoveryController.text) ?? 90,
            recoveryUnit: _stridesRecoveryUnit,
          );
        }
        details = EasyRunWorkout(
          distance: distance,
          distanceUnit: _distanceUnit,
          strides: strides,
        ).toJson();
        break;

      case WorkoutType.qualitySession:
        details = QualitySessionWorkout(
          warmup: double.tryParse(_warmupController.text) ?? 2.0,
          warmupUnit: _warmupUnit,
          sets: _sets,
          cooldown: double.tryParse(_cooldownController.text) ?? 2.0,
          cooldownUnit: _cooldownUnit,
        ).toJson();
        break;

      case WorkoutType.race:
        details = RaceWorkout(
          warmup: double.tryParse(_warmupController.text) ?? 2.0,
          warmupUnit: _warmupUnit,
          raceName: _raceNameController.text,
          raceDistance: double.tryParse(_raceDistanceController.text) ?? 5.0,
          raceDistanceUnit: _raceDistanceUnit,
          cooldown: double.tryParse(_cooldownController.text) ?? 1.0,
          cooldownUnit: _cooldownUnit,
        ).toJson();
        break;

      case WorkoutType.crossTraining:
        details = CrossTrainingWorkout(
          type: _crossTrainingType,
          duration: double.tryParse(_durationController.text) ?? 60,
          durationUnit: _durationUnit,
          intensity: _intensity,
          exercises: _strengthExercises.isEmpty ? null : _strengthExercises,
        ).toJson();
        break;

      case WorkoutType.restDay:
        details = RestDayWorkout(
          reason: _restReasonController.text.isEmpty
              ? null
              : _restReasonController.text,
        ).toJson();
        break;

      case WorkoutType.note:
        details = {};
        break;
    }

    return WorkoutDefinition(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      date: _selectedDate,
      customName: _nameController.text.isEmpty ? null : _nameController.text,
      coachNotes: _notesController.text.isEmpty ? null : _notesController.text,
      details: details,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _distanceController.dispose();
    _stridesRepsController.dispose();
    _stridesDistanceController.dispose();
    _stridesRecoveryController.dispose();
    _warmupController.dispose();
    _cooldownController.dispose();
    _raceNameController.dispose();
    _raceDistanceController.dispose();
    _durationController.dispose();
    _restReasonController.dispose();
    super.dispose();
  }
}

// Dialog to add a workout set
class _AddSetDialog extends StatefulWidget {
  final Function(WorkoutSet) onSetAdded;

  const _AddSetDialog({required this.onSetAdded});

  @override
  State<_AddSetDialog> createState() => _AddSetDialogState();
}

class _AddSetDialogState extends State<_AddSetDialog> {
  String _setType = 'running'; // running, rest

  final TextEditingController _repsController =
      TextEditingController(text: '8');
  final TextEditingController _distanceController =
      TextEditingController(text: '400');
  WorkoutUnit _distanceUnit = WorkoutUnit.meters;
  WorkoutIntensity _intensity = WorkoutIntensity.interval;
  final TextEditingController _recoveryController =
      TextEditingController(text: '90');
  RecoveryUnit _recoveryUnit = RecoveryUnit.secondsJog;

  final TextEditingController _restDurationController =
      TextEditingController(text: '3');
  RecoveryUnit _restUnit = RecoveryUnit.minutesWalk;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Set'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'running', label: Text('Running')),
                ButtonSegment(value: 'rest', label: Text('Rest')),
              ],
              selected: {_setType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _setType = newSelection.first);
              },
            ),
            const SizedBox(height: 16),
            if (_setType == 'running') ...[
              TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reps'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _distanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Distance'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<WorkoutUnit>(
                    value: _distanceUnit,
                    items: [WorkoutUnit.meters, WorkoutUnit.kilometers]
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit.shortName),
                            ))
                        .toList(),
                    onChanged: (unit) {
                      if (unit != null) {
                        setState(() => _distanceUnit = unit);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<WorkoutIntensity>(
                initialValue: _intensity,
                decoration: const InputDecoration(labelText: 'Intensity'),
                items: WorkoutIntensity.values
                    .map((intensity) => DropdownMenuItem(
                          value: intensity,
                          child: Text(intensity.displayName),
                        ))
                    .toList(),
                onChanged: (intensity) {
                  if (intensity != null) {
                    setState(() => _intensity = intensity);
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _recoveryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Recovery'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<RecoveryUnit>(
                      value: _recoveryUnit,
                      isExpanded: true,
                      items: RecoveryUnit.values
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit.displayName),
                              ))
                          .toList(),
                      onChanged: (unit) {
                        if (unit != null) {
                          setState(() => _recoveryUnit = unit);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _restDurationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duration'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<RecoveryUnit>(
                      value: _restUnit,
                      isExpanded: true,
                      items: [
                        RecoveryUnit.minutesWalk,
                        RecoveryUnit.secondsWalk,
                      ]
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit.displayName),
                              ))
                          .toList(),
                      onChanged: (unit) {
                        if (unit != null) {
                          setState(() => _restUnit = unit);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            WorkoutSet set;
            if (_setType == 'running') {
              set = RunningSet(
                reps: int.tryParse(_repsController.text) ?? 8,
                distance: double.tryParse(_distanceController.text) ?? 400,
                distanceUnit: _distanceUnit,
                intensity: _intensity,
                recovery: double.tryParse(_recoveryController.text) ?? 90,
                recoveryUnit: _recoveryUnit,
              );
            } else {
              set = RestSet(
                duration: double.tryParse(_restDurationController.text) ?? 3,
                unit: WorkoutUnit.minutes,
              );
            }
            widget.onSetAdded(set);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _repsController.dispose();
    _distanceController.dispose();
    _recoveryController.dispose();
    _restDurationController.dispose();
    super.dispose();
  }
}

// Dialog to add strength exercise
class _AddStrengthExerciseDialog extends StatefulWidget {
  final Function(StrengthExercise) onExerciseAdded;

  const _AddStrengthExerciseDialog({required this.onExerciseAdded});

  @override
  State<_AddStrengthExerciseDialog> createState() =>
      _AddStrengthExerciseDialogState();
}

class _AddStrengthExerciseDialogState
    extends State<_AddStrengthExerciseDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _setsController =
      TextEditingController(text: '3');
  final TextEditingController _repsController =
      TextEditingController(text: '12');
  final TextEditingController _weightController = TextEditingController();
  String? _unit = 'bodyweight';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Exercise'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Single Leg Squats',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sets'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Weight (optional)'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _unit,
                  items: ['bodyweight', 'kg', 'lbs']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (u) => setState(() => _unit = u),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;

            final exercise = StrengthExercise(
              name: _nameController.text,
              sets: int.tryParse(_setsController.text) ?? 3,
              reps: int.tryParse(_repsController.text) ?? 12,
              weight: _weightController.text.isEmpty
                  ? null
                  : double.tryParse(_weightController.text),
              unit: _unit == 'bodyweight'
                  ? _unit
                  : (_weightController.text.isEmpty ? null : _unit),
            );
            widget.onExerciseAdded(exercise);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
