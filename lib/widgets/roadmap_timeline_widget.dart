// Roadmap Timeline Widget
//
// Visual timeline widget showing athlete's recovery journey from current state to goal.
// Features:
// - Color-coded phases (red → yellow → green)
// - Milestone markers with week numbers
// - Progress indicators
// - Expected ROM improvements at each checkpoint
// - Interactive phase details

import 'package:flutter/material.dart';

class RoadmapTimelineWidget extends StatelessWidget {
  final List<TimelinePhase> phases;
  final List<Milestone> milestones;
  final int currentWeek;
  final Function(int)? onPhaseClicked;

  const RoadmapTimelineWidget({
    super.key,
    required this.phases,
    required this.milestones,
    this.currentWeek = 0,
    this.onPhaseClicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Recovery Roadmap',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow this structured path to reach your goals',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Timeline visualization
          _buildTimeline(context),

          const SizedBox(height: 24),

          // Phase cards
          ..._buildPhaseCards(context),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: milestones.length,
        itemBuilder: (context, index) {
          final milestone = milestones[index];
          final isPast = currentWeek > milestone.weekNumber;
          final isCurrent = currentWeek == milestone.weekNumber;
          final isCompleted = milestone.isCompleted || isPast;

          return _buildMilestoneNode(
            context,
            milestone: milestone,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: index == milestones.length - 1,
          );
        },
      ),
    );
  }

  Widget _buildMilestoneNode(
    BuildContext context, {
    required Milestone milestone,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color nodeColor = isCompleted
        ? Colors.green
        : isCurrent
            ? Colors.orange
            : Colors.grey[300]!;

    Color lineColor = isCompleted ? Colors.green : Colors.grey[300]!;

    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Milestone node with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: isCurrent ? 50 : 40,
              height: isCurrent ? 50 : 40,
              decoration: BoxDecoration(
                color: nodeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? Colors.orange : nodeColor,
                  width: isCurrent ? 3 : 2,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 20),
                          );
                        },
                      )
                    : Text(
                        'W${milestone.weekNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Week label
            SizedBox(
              width: 80,
              child: Text(
                'Week ${milestone.weekNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.orange : Colors.grey[700],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Title
            SizedBox(
              width: 80,
              child: Text(
                milestone.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),

        // Connecting line (if not last)
        if (!isLast)
          Container(
            width: 40,
            height: 2,
            margin: const EdgeInsets.only(bottom: 60),
            color: lineColor,
          ),
      ],
    );
  }

  List<Widget> _buildPhaseCards(BuildContext context) {
    return phases.asMap().entries.map((entry) {
      final index = entry.key;
      final phase = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: PhaseCard(
          phase: phase,
          phaseNumber: index + 1,
          onTap: onPhaseClicked != null ? () => onPhaseClicked!(index) : null,
        ),
      );
    }).toList();
  }
}

class PhaseCard extends StatelessWidget {
  final TimelinePhase phase;
  final int phaseNumber;
  final VoidCallback? onTap;

  const PhaseCard({
    super.key,
    required this.phase,
    required this.phaseNumber,
    this.onTap,
  });

  Color _getPhaseColor() {
    switch (phaseNumber) {
      case 1:
        return Colors.red[400]!;
      case 2:
        return Colors.orange[400]!;
      case 3:
        return Colors.lightGreen[400]!;
      case 4:
        return Colors.green[600]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getPhaseIcon() {
    switch (phaseNumber) {
      case 1:
        return Icons.foundation;
      case 2:
        return Icons.fitness_center;
      case 3:
        return Icons.trending_up;
      case 4:
        return Icons.emoji_events;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = _getPhaseColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: phaseColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPhaseIcon(),
                      color: phaseColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phase $phaseNumber: ${phase.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          phase.weekRange,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),

              // Goals
              _buildSection(
                context,
                title: 'Goals',
                icon: Icons.flag,
                items: phase.goals,
              ),

              const SizedBox(height: 12),

              // Expected Improvements
              _buildSection(
                context,
                title: 'Expected Improvements',
                icon: Icons.trending_up,
                items: phase.expectedImprovements,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...items.take(2).map((item) => Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.grey[600])),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            )),
        if (items.length > 2)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 2),
            child: Text(
              '+ ${items.length - 2} more...',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}

// Data Models for Timeline

class TimelinePhase {
  final String name;
  final String weekRange;
  final List<String> goals;
  final List<String> expectedImprovements;
  final List<String> focusAreas;

  TimelinePhase({
    required this.name,
    required this.weekRange,
    required this.goals,
    required this.expectedImprovements,
    required this.focusAreas,
  });
}

class Milestone {
  final int weekNumber;
  final String title;
  final DateTime targetDate;
  final List<String> expectedImprovements;
  final bool isCompleted;

  Milestone({
    required this.weekNumber,
    required this.title,
    required this.targetDate,
    required this.expectedImprovements,
    this.isCompleted = false,
  });
}

/// Example Usage:
///
/// ```dart
/// RoadmapTimelineWidget(
///   currentWeek: 4,
///   phases: [
///     TimelinePhase(
///       name: 'Foundation & Acute Correction',
///       weekRange: 'Weeks 1-4',
///       goals: [
///         'Establish baseline mobility',
///         'Reduce acute injury risk',
///       ],
///       expectedImprovements: [
///         '+5-10% ROM improvement',
///         '30-40% pain reduction',
///       ],
///       focusAreas: ['Mobility', 'Corrective exercises'],
///     ),
///     // ... more phases
///   ],
///   milestones: [
///     Milestone(
///       weekNumber: 2,
///       title: 'Early Adaptation',
///       targetDate: DateTime.now().add(Duration(days: 14)),
///       expectedImprovements: ['Pain reduction', 'Movement awareness'],
///     ),
///     // ... more milestones
///   ],
///   onPhaseClicked: (phaseIndex) {
///     // Navigate to phase details
///     developer.log('Phase $phaseIndex clicked');
///   },
/// )
/// ```
