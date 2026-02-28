// Garmin-Style Workout Builder Screen
// Create and edit structured workouts like Garmin Connect
// Supports: Warm-up, Run, Walk, Intervals, Recovery, Cool-down, Repeats

import 'package:flutter/material.dart';
import '../models/workout_step.dart';
import '../services/workout_service.dart';

class GarminWorkoutBuilderScreen extends StatefulWidget {
  final StructuredWorkout? existingWorkout;
  final DateTime? scheduledDate;

  const GarminWorkoutBuilderScreen({
    super.key,
    this.existingWorkout,
    this.scheduledDate,
  });

  @override
  State<GarminWorkoutBuilderScreen> createState() =>
      _GarminWorkoutBuilderScreenState();
}

class _GarminWorkoutBuilderScreenState
    extends State<GarminWorkoutBuilderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final WorkoutService _workoutService = WorkoutService();

  List<WorkoutStep> _steps = [];
  bool _isSaving = false;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingWorkout != null) {
      _nameController.text = widget.existingWorkout!.name;
      _notesController.text = widget.existingWorkout!.notes ?? '';
      _steps = List.from(widget.existingWorkout!.steps);
    } else {
      _nameController.text = 'Run Workout';
      // Add default steps like Garmin Connect - use unique IDs
      final now = DateTime.now().millisecondsSinceEpoch;
      _steps = [
        WorkoutStep(
            id: '${now}_warmup',
            type: StepType.warmUp,
            target: StepTarget.open,
            order: 0),
        WorkoutStep(
            id: '${now}_run',
            type: StepType.run,
            target: StepTarget.distance,
            targetValue: 1609.34,
            targetUnit: 'mi',
            order: 1),
        WorkoutStep(
            id: '${now}_cooldown',
            type: StepType.coolDown,
            target: StepTarget.open,
            order: 2),
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: _confirmExit,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKOUTS',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_run, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _editWorkoutName,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nameController.text,
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: Colors.grey[700], fontSize: 16)),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save Workout',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Steps List (Left side)
        Expanded(
          flex: 2,
          child: _buildStepsList(),
        ),
        // Actions Panel (Right side)
        SizedBox(
          width: 220,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: _buildActionsPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(child: _buildStepsList()),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: _buildActionButtonsRow(),
        ),
      ],
    );
  }

  Widget _buildActionButtonsRow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showAddStepDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Step'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showAddRepeatDialog,
                icon: const Icon(Icons.repeat, size: 18),
                label: const Text('Add Repeat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWorkoutSummary(),
      ],
    );
  }

  Widget _buildStepsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.directions_run, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_steps.length} steps • ${_getTotalEstTime()}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Steps
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _steps.length,
              onReorder: _reorderSteps,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return _buildStepCard(step, index, key: ValueKey(step.id));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(WorkoutStep step, int index, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: step.typeColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.drag_indicator,
                        color: Colors.grey[400], size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Step icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: step.typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(step.typeIcon, color: step.typeColor, size: 18),
                ),
                const SizedBox(width: 8),
                // Step name
                Expanded(
                  child: Text(
                    step.typeName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                // Edit button
                TextButton(
                  onPressed: () => _editStep(index),
                  child: const Text('Edit Step',
                      style: TextStyle(color: Colors.blue, fontSize: 13)),
                ),
                // Delete button
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.grey[400], size: 20),
                  onPressed: () => _deleteStep(index),
                ),
              ],
            ),
          ),
          // Step details
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
            child: _buildStepDetails(step),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDetails(WorkoutStep step) {
    if (step.type == StepType.repeat && step.repeatSteps != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Repeat ${step.repeatCount ?? 2}x',
              style: TextStyle(
                  color: Colors.amber[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          ...step.repeatSteps!.map((s) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    Container(width: 3, height: 24, color: s.typeColor),
                    const SizedBox(width: 8),
                    Icon(s.typeIcon, color: s.typeColor, size: 16),
                    const SizedBox(width: 6),
                    Text(s.typeName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.targetDescription,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.targetDescription,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              if (step.target == StepTarget.open)
                Text(
                  'Duration',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
            ],
          ),
        ),
        if (step.target == StepTarget.distance && step.targetValue != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getEstimatedTime(step),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Est Time',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
      ],
    );
  }

  String _getEstimatedTime(WorkoutStep step) {
    final duration = step.estimatedDuration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildActionsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Add a Step button
        ElevatedButton.icon(
          onPressed: _showAddStepDialog,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add a Step'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),

        // Add a Repeat button
        OutlinedButton.icon(
          onPressed: _showAddRepeatDialog,
          icon: const Icon(Icons.repeat, size: 18),
          label: const Text('Add a Repeat'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: const BorderSide(color: Colors.blue),
          ),
        ),
        const SizedBox(height: 24),

        // Add Note
        InkWell(
          onTap: _editNotes,
          child: Row(
            children: [
              const Icon(Icons.note_add, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Add Note',
                  style: TextStyle(color: Colors.blue, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Info text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Your workout will be saved and synced across your devices.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),

        const Spacer(),

        // Total workout summary
        _buildWorkoutSummary(),
      ],
    );
  }

  Widget _buildWorkoutSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Workout Summary',
                style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Est. Time', _getTotalEstTime()),
          const SizedBox(height: 6),
          _buildSummaryRow('Distance', _getTotalDistance()),
          const SizedBox(height: 6),
          _buildSummaryRow('Steps', '${_steps.length}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  String _getTotalEstTime() {
    final total = _steps.fold<Duration>(
        Duration.zero, (sum, step) => sum + step.estimatedDuration);
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    final seconds = total.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getTotalDistance() {
    double total = 0;
    for (final step in _steps) {
      if (step.target == StepTarget.distance && step.targetValue != null) {
        total += step.targetValue!;
      }
    }
    if (total == 0) return '--';
    final mi = total / 1609.34;
    return '${mi.toStringAsFixed(2)} mi';
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
      _isEdited = true;
    });
  }

  void _deleteStep(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Step?'),
        content: Text(
            'Are you sure you want to delete "${_steps[index].typeName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _steps.removeAt(index);
                _isEdited = true;
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editStep(int index) {
    _showStepEditor(_steps[index], (updatedStep) {
      setState(() {
        _steps[index] = updatedStep;
        _isEdited = true;
      });
    });
  }

  void _showAddStepDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Add Step',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStepTypeOption(StepType.warmUp),
                _buildStepTypeOption(StepType.run),
                _buildStepTypeOption(StepType.walk),
                _buildStepTypeOption(StepType.interval),
                _buildStepTypeOption(StepType.recovery),
                _buildStepTypeOption(StepType.coolDown),
                _buildStepTypeOption(StepType.rest),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTypeOption(StepType type) {
    final step = WorkoutStep(type: type, order: _steps.length);
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showStepEditor(step, (newStep) {
          setState(() {
            _steps.add(newStep);
            _isEdited = true;
          });
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: step.typeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: step.typeColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(step.typeIcon, color: step.typeColor, size: 28),
            const SizedBox(height: 4),
            Text(
              step.typeName,
              style: TextStyle(
                  color: step.typeColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRepeatDialog() {
    showDialog(
      context: context,
      builder: (context) => _RepeatConfigDialog(
        onSave: (repeatStep) {
          setState(() {
            _steps.add(repeatStep);
            _isEdited = true;
          });
        },
      ),
    );
  }

  void _showStepEditor(WorkoutStep step, Function(WorkoutStep) onSave) {
    showDialog(
      context: context,
      builder: (context) => _StepEditorDialog(
        step: step,
        onSave: onSave,
      ),
    );
  }

  void _editWorkoutName() {
    final controller = TextEditingController(text: _nameController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter workout name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _nameController.text = controller.text;
                _isEdited = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editNotes() {
    final controller = TextEditingController(text: _notesController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Add notes for this workout...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notesController.text = controller.text;
                _isEdited = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkout() async {
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one step to the workout')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final workout = StructuredWorkout(
        id: widget.existingWorkout?.id,
        name: _nameController.text.trim().isEmpty
            ? 'Run Workout'
            : _nameController.text.trim(),
        steps: _steps,
        scheduledDate: widget.scheduledDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _workoutService.saveWorkout(workout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout saved successfully!'),
            backgroundColor: Colors.green[600],
          ),
        );
        Navigator.pop(context, workout);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving workout: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _confirmExit() {
    if (!_isEdited) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Step Editor Dialog
class _StepEditorDialog extends StatefulWidget {
  final WorkoutStep step;
  final Function(WorkoutStep) onSave;

  const _StepEditorDialog({
    required this.step,
    required this.onSave,
  });

  @override
  State<_StepEditorDialog> createState() => _StepEditorDialogState();
}

class _StepEditorDialogState extends State<_StepEditorDialog> {
  late StepTarget _selectedTarget;
  late TextEditingController _valueController;
  late TextEditingController _paceMinController;
  late TextEditingController _paceMaxController;
  String _selectedUnit = 'mi';
  int _selectedHRZone = 3;

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.step.target;
    _selectedUnit = widget.step.targetUnit ?? 'mi';

    double displayValue = 0;
    if (widget.step.targetValue != null) {
      if (widget.step.target == StepTarget.distance) {
        displayValue =
            widget.step.targetValue! / (_selectedUnit == 'mi' ? 1609.34 : 1000);
      } else if (widget.step.target == StepTarget.duration) {
        displayValue =
            widget.step.targetValue! / 60; // Convert seconds to minutes
      } else {
        displayValue = widget.step.targetValue!;
      }
    }

    _valueController = TextEditingController(
      text: displayValue > 0 ? displayValue.toStringAsFixed(2) : '',
    );
    _paceMinController = TextEditingController(
      text: widget.step.targetPaceMin?.toStringAsFixed(2) ?? '5.00',
    );
    _paceMaxController = TextEditingController(
      text: widget.step.targetPaceMax?.toStringAsFixed(2) ?? '6.00',
    );
    _selectedHRZone = widget.step.targetHRZone ?? 3;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _paceMinController.dispose();
    _paceMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.step.typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.step.typeIcon,
                color: widget.step.typeColor, size: 24),
          ),
          const SizedBox(width: 12),
          Text(widget.step.typeName),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Target Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StepTarget.values.map((target) {
                  final isSelected = _selectedTarget == target;
                  return ChoiceChip(
                    label: Text(_getTargetLabel(target)),
                    selected: isSelected,
                    selectedColor: Colors.blue[100],
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTarget = target);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Target value input based on selected target
              _buildTargetInput(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTargetInput() {
    switch (_selectedTarget) {
      case StepTarget.distance:
        return _buildDistanceInput();
      case StepTarget.duration:
        return _buildDurationInput();
      case StepTarget.heartRate:
        return _buildHRZoneInput();
      case StepTarget.pace:
        return _buildPaceInput();
      case StepTarget.calories:
        return _buildCaloriesInput();
      case StepTarget.open:
        return _buildOpenInput();
    }
  }

  Widget _buildDistanceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '1.00',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUnit,
                  items: ['mi', 'km', 'm'].map((unit) {
                    return DropdownMenuItem(value: unit, child: Text(unit));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedUnit = value!);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _valueController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: '10',
            suffixText: 'minutes',
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildHRZoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Heart Rate Zone',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [1, 2, 3, 4, 5].map((zone) {
            final isSelected = _selectedHRZone == zone;
            final zoneColors = [
              Colors.grey,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.red
            ];
            return GestureDetector(
              onTap: () => setState(() => _selectedHRZone = zone),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? zoneColors[zone - 1]
                      : zoneColors[zone - 1].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isSelected ? zoneColors[zone - 1] : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$zone',
                    style: TextStyle(
                      color: isSelected ? Colors.white : zoneColors[zone - 1],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getZoneDescription(_selectedHRZone),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  String _getZoneDescription(int zone) {
    switch (zone) {
      case 1:
        return 'Recovery: 50-60% max HR';
      case 2:
        return 'Endurance: 60-70% max HR';
      case 3:
        return 'Tempo: 70-80% max HR';
      case 4:
        return 'Threshold: 80-90% max HR';
      case 5:
        return 'Max: 90-100% max HR';
      default:
        return '';
    }
  }

  Widget _buildPaceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Pace Range',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _paceMinController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '5:00',
                  labelText: 'Min pace',
                  suffixText: '/km',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('to', style: TextStyle(color: Colors.grey[600])),
            ),
            Expanded(
              child: TextField(
                controller: _paceMaxController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '6:00',
                  labelText: 'Max pace',
                  suffixText: '/km',
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaloriesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Calories',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _valueController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: '200',
            suffixText: 'kcal',
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildOpenInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Press lap button to advance to the next step during your workout.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _saveStep() {
    double? targetValue;

    if (_selectedTarget == StepTarget.distance) {
      final value = double.tryParse(_valueController.text) ?? 1.0;
      targetValue = value *
          (_selectedUnit == 'mi'
              ? 1609.34
              : (_selectedUnit == 'km' ? 1000 : 1));
    } else if (_selectedTarget == StepTarget.duration) {
      final value = double.tryParse(_valueController.text) ?? 10;
      targetValue = value * 60; // Convert to seconds
    } else if (_selectedTarget == StepTarget.calories) {
      targetValue = double.tryParse(_valueController.text);
    }

    final updatedStep = widget.step.copyWith(
      target: _selectedTarget,
      targetValue: targetValue,
      targetUnit: _selectedUnit,
      targetPaceMin: double.tryParse(_paceMinController.text),
      targetPaceMax: double.tryParse(_paceMaxController.text),
      targetHRZone: _selectedHRZone,
    );

    widget.onSave(updatedStep);
    Navigator.pop(context);
  }

  String _getTargetLabel(StepTarget target) {
    switch (target) {
      case StepTarget.open:
        return 'Lap Button';
      case StepTarget.distance:
        return 'Distance';
      case StepTarget.duration:
        return 'Time';
      case StepTarget.heartRate:
        return 'HR Zone';
      case StepTarget.pace:
        return 'Pace';
      case StepTarget.calories:
        return 'Calories';
    }
  }
}

// Repeat Config Dialog
class _RepeatConfigDialog extends StatefulWidget {
  final Function(WorkoutStep) onSave;

  const _RepeatConfigDialog({required this.onSave});

  @override
  State<_RepeatConfigDialog> createState() => _RepeatConfigDialogState();
}

class _RepeatConfigDialogState extends State<_RepeatConfigDialog> {
  int _repeatCount = 4;
  late List<WorkoutStep> _repeatSteps;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().millisecondsSinceEpoch;
    _repeatSteps = [
      WorkoutStep(
          id: '${now}_interval',
          type: StepType.interval,
          target: StepTarget.distance,
          targetValue: 400,
          targetUnit: 'm',
          order: 0),
      WorkoutStep(
          id: '${now}_recovery',
          type: StepType.recovery,
          target: StepTarget.distance,
          targetValue: 200,
          targetUnit: 'm',
          order: 1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.repeat, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Add Repeat'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Number of Repeats',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _repeatCount > 1
                      ? () => setState(() => _repeatCount--)
                      : null,
                  icon: Icon(Icons.remove_circle,
                      color: _repeatCount > 1 ? Colors.blue : Colors.grey),
                  iconSize: 32,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_repeatCount',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _repeatCount++),
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  iconSize: 32,
                ),
                const Spacer(),
                Text('× repeats',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Steps to Repeat',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ..._repeatSteps.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final step = entry.value;
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: step.typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(step.typeIcon,
                            color: step.typeColor, size: 20),
                      ),
                      title: Text(step.typeName,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(step.targetDescription,
                          style: TextStyle(color: Colors.grey[600])),
                      trailing: IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.grey),
                        onPressed: () =>
                            setState(() => _repeatSteps.removeAt(idx)),
                      ),
                    );
                  }),
                  const Divider(height: 1),
                  TextButton.icon(
                    onPressed: _addStepToRepeat,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Step to Repeat'),
                  ),
                ],
              ),
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
          onPressed: _repeatSteps.isEmpty
              ? null
              : () {
                  final repeatStep = WorkoutStep(
                    type: StepType.repeat,
                    repeatCount: _repeatCount,
                    repeatSteps: _repeatSteps,
                    order: 0,
                  );
                  widget.onSave(repeatStep);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _addStepToRepeat() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Step to Repeat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StepType.run,
                StepType.interval,
                StepType.recovery,
                StepType.walk,
                StepType.rest
              ].map((type) {
                final step =
                    WorkoutStep(type: type, order: _repeatSteps.length);
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _repeatSteps.add(step);
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: step.typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: step.typeColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(step.typeIcon, color: step.typeColor, size: 28),
                        const SizedBox(height: 4),
                        Text(step.typeName,
                            style:
                                TextStyle(color: step.typeColor, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
