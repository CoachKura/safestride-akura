// Structured Workout Detail Screen - Garmin-style step-by-step workout builder
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/structured_workout.dart';
import '../services/structured_workout_service.dart';
import 'step_editor_screen.dart';

class StructuredWorkoutDetailScreen extends StatefulWidget {
  final StructuredWorkout? workout; // null = create new, not null = edit

  const StructuredWorkoutDetailScreen({
    super.key,
    this.workout,
  });

  @override
  State<StructuredWorkoutDetailScreen> createState() =>
      _StructuredWorkoutDetailScreenState();
}

class _StructuredWorkoutDetailScreenState
    extends State<StructuredWorkoutDetailScreen> {
  final _service = StructuredWorkoutService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _activityType = 'Running';
  List<WorkoutStep> _steps = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _nameController.text = widget.workout!.workoutName;
      _descriptionController.text = widget.workout!.description ?? '';
      _activityType = widget.workout!.activityType;
      _steps = List.from(widget.workout!.steps);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one step to the workout')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Calculate estimated duration and distance
      double? estimatedDuration = 0;
      double? estimatedDistance = 0;

      for (var step in _steps) {
        if (step.durationType == DurationType.time &&
            step.durationValue != null) {
          estimatedDuration = estimatedDuration! + step.durationValue!;
        } else if (step.durationType == DurationType.distance &&
            step.durationValue != null) {
          estimatedDistance = estimatedDistance! + step.durationValue!;
        }
      }

      final workout = StructuredWorkout(
        id: widget.workout?.id ?? const Uuid().v4(),
        coachId: user.id,
        workoutName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        activityType: _activityType,
        steps: _steps,
        estimatedDuration:
            (estimatedDuration ?? 0) > 0 ? estimatedDuration : null,
        estimatedDistance:
            (estimatedDistance ?? 0) > 0 ? estimatedDistance : null,
        createdAt: widget.workout?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.workout == null) {
        await _service.createWorkout(workout);
      } else {
        await _service.updateWorkout(workout);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addStep() async {
    final newStep = await Navigator.of(context).push<WorkoutStep>(
      MaterialPageRoute(
        builder: (context) => const StepEditorScreen(),
      ),
    );

    if (newStep != null) {
      setState(() {
        _steps.add(newStep);
      });
    }
  }

  Future<void> _editStep(int index) async {
    final editedStep = await Navigator.of(context).push<WorkoutStep>(
      MaterialPageRoute(
        builder: (context) => StepEditorScreen(step: _steps[index]),
      ),
    );

    if (editedStep != null) {
      setState(() {
        _steps[index] = editedStep;
      });
    }
  }

  void _deleteStep(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Step'),
        content: const Text('Are you sure you want to delete this step?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _steps.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout == null ? 'Create Workout' : 'Edit Workout'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkout,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Workout Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Workout Name *',
                      hintText: 'e.g., "Long Run with Intervals"',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a workout name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add notes about this workout',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Activity Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _activityType,
                    decoration: const InputDecoration(
                      labelText: 'Activity Type',
                      prefixIcon: Icon(Icons.directions_run),
                    ),
                    items: ['Running', 'Cycling', 'Swimming', 'Other']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _activityType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Workout Steps Section
                  Row(
                    children: [
                      const Icon(Icons.format_list_numbered, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'WORKOUT STEPS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_steps.length} steps',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Steps List
                  if (_steps.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No steps added yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Add Step" to start building your workout',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: _reorderSteps,
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return _buildStepCard(step, index);
                      },
                    ),
                ],
              ),
            ),

            // Add Step Button (Fixed at bottom)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: const Text('ADD STEP'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(WorkoutStep step, int index) {
    return Card(
      key: ValueKey(step.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _editStep(index),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Step Number & Drag Handle
              Column(
                children: [
                  const Icon(Icons.drag_handle, color: Colors.grey),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _getStepColor(step.stepType),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Step Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Type
                    Text(
                      step.stepTypeDisplay,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Duration
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          step.durationDisplay ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Intensity Target
                    if (step.intensityType != IntensityType.noTarget)
                      Row(
                        children: [
                          Icon(Icons.favorite,
                              size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            step.targetDisplay ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteStep(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStepColor(WorkoutStepType type) {
    switch (type) {
      case WorkoutStepType.warmUp:
        return Colors.orange;
      case WorkoutStepType.run:
        return Colors.blue;
      case WorkoutStepType.recovery:
        return Colors.green;
      case WorkoutStepType.rest:
        return Colors.grey;
      case WorkoutStepType.coolDown:
        return Colors.purple;
      case WorkoutStepType.repeat:
        return Colors.teal;
      case WorkoutStepType.other:
        return Colors.brown;
    }
  }
}
