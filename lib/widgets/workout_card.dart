import 'package:flutter/material.dart';
import '../models/workout_calendar_entry.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutCalendarEntry entry;
  final String? label;
  final Color? labelColor;
  final bool showActions;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onTap;

  const WorkoutCard({
    super.key,
    required this.entry,
    this.label,
    this.labelColor,
    this.showActions = true,
    this.onComplete,
    this.onSkip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: 2,
          ),
          boxShadow: [
            if (entry.isPending && label == 'TODAY')
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label and Status Row
            Row(
              children: [
                if (label != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (labelColor ?? Colors.blue).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label!,
                      style: TextStyle(
                        color: labelColor ?? Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),

            // Workout Name
            Text(
              entry.workout.workoutName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Workout Info
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${entry.workout.estimatedDurationMinutes} min',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${entry.workout.exercises.length} exercises',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),

            // Workout Type and Difficulty
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildChip(
                  entry.workout.workoutType.toUpperCase(),
                  _getWorkoutTypeColor(entry.workout.workoutType),
                ),
                _buildChip(
                  entry.workout.difficulty.toUpperCase(),
                  _getDifficultyColor(entry.workout.difficulty),
                ),
              ],
            ),

            // Completion Info (if completed)
            if (entry.isCompleted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completed: ${entry.actualDurationMinutes} min',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          if (entry.difficultyRating != null)
                            Row(
                              children: [
                                Text(
                                  'Difficulty: ',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]),
                                ),
                                ...List.generate(
                                  5,
                                  (index) => Icon(
                                    index < entry.difficultyRating!
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                ),
                                if (entry.painLevel != null)
                                  Text(
                                    '  Pain: ${entry.painLevel}/10',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700]),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons (if pending and actions enabled)
            if (entry.isPending &&
                showActions &&
                (onComplete != null || onSkip != null)) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onComplete != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (onComplete != null && onSkip != null)
                    const SizedBox(width: 8),
                  if (onSkip != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSkip,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Skip'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

  Widget _buildStatusBadge() {
    IconData icon;
    Color color;
    String text;

    switch (entry.status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        text = 'Completed';
        break;
      case 'skipped':
        icon = Icons.cancel;
        color = Colors.red;
        text = 'Skipped';
        break;
      case 'rescheduled':
        icon = Icons.event;
        color = Colors.orange;
        text = 'Rescheduled';
        break;
      default:
        icon = Icons.schedule;
        color = Colors.blue;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (entry.isCompleted) return Colors.green.withValues(alpha: 0.05);
    if (entry.isSkipped) return Colors.red.withValues(alpha: 0.05);
    if (label == 'TODAY' && entry.isPending) return Colors.white;
    return Colors.white;
  }

  Color _getBorderColor() {
    if (entry.isCompleted) return Colors.green.withValues(alpha: 0.3);
    if (entry.isSkipped) return Colors.red.withValues(alpha: 0.3);
    if (label == 'TODAY' && entry.isPending) return Colors.green;
    return Colors.grey[300]!;
  }

  Color _getWorkoutTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'rehab':
        return Colors.purple;
      case 'strength':
        return Colors.red;
      case 'mobility':
        return Colors.blue;
      case 'cardio':
        return Colors.orange;
      case 'rest':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
