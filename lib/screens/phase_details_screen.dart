// Phase Details Screen
//
// Deep-dive into a specific recovery phase with:
// - Detailed goals and focus areas
// - Week-by-week breakdown
// - Training modifications
// - Expected improvements
// - Progress tracking

import 'package:flutter/material.dart';
import '../services/assessment_report_generator.dart';

class PhaseDetailsScreen extends StatefulWidget {
  final RoadmapPhase phase;
  final int phaseNumber;

  const PhaseDetailsScreen({
    super.key,
    required this.phase,
    required this.phaseNumber,
  });

  @override
  _PhaseDetailsScreenState createState() => _PhaseDetailsScreenState();
}

class _PhaseDetailsScreenState extends State<PhaseDetailsScreen> {
  bool _showAllGoals = false;
  bool _showAllFocusAreas = false;
  bool _showAllModifications = false;

  @override
  Widget build(BuildContext context) {
    Color phaseColor = _getPhaseColor(widget.phaseNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text('Phase ${widget.phaseNumber}: ${widget.phase.phaseName}'),
        backgroundColor: phaseColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase Header
            _buildPhaseHeader(phaseColor),

            // Phase Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoalsSection(),
                  const SizedBox(height: 24),
                  _buildFocusAreasSection(),
                  const SizedBox(height: 24),
                  _buildExpectedImprovementsSection(),
                  const SizedBox(height: 24),
                  _buildTrainingModificationsSection(),
                  const SizedBox(height: 24),
                  _buildWeekByWeekBreakdown(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPhaseHeader(Color phaseColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [phaseColor, phaseColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPhaseIcon(widget.phaseNumber),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.phase.phaseName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.phase.weekRange,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Phase ${widget.phaseNumber} of 4',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    final displayGoals = _showAllGoals
        ? widget.phase.goals
        : widget.phase.goals.take(3).toList();

    return _buildExpandableSection(
      title: '🎯 Phase Goals',
      icon: Icons.flag,
      color: Colors.blue,
      items: displayGoals,
      showAll: _showAllGoals,
      totalCount: widget.phase.goals.length,
      onToggle: () {
        setState(() {
          _showAllGoals = !_showAllGoals;
        });
      },
    );
  }

  Widget _buildFocusAreasSection() {
    final displayAreas = _showAllFocusAreas
        ? widget.phase.focusAreas
        : widget.phase.focusAreas.take(3).toList();

    return _buildExpandableSection(
      title: '🔧 Focus Areas',
      icon: Icons.center_focus_strong,
      color: Colors.orange,
      items: displayAreas,
      showAll: _showAllFocusAreas,
      totalCount: widget.phase.focusAreas.length,
      onToggle: () {
        setState(() {
          _showAllFocusAreas = !_showAllFocusAreas;
        });
      },
    );
  }

  Widget _buildExpectedImprovementsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.trending_up, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '📈 Expected Improvements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.phase.expectedImprovements.map((improvement) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        improvement,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingModificationsSection() {
    final displayMods = _showAllModifications
        ? widget.phase.trainingModifications
        : widget.phase.trainingModifications.take(3).toList();

    return _buildExpandableSection(
      title: '🏃 Training Modifications',
      icon: Icons.directions_run,
      color: Colors.purple,
      items: displayMods,
      showAll: _showAllModifications,
      totalCount: widget.phase.trainingModifications.length,
      onToggle: () {
        setState(() {
          _showAllModifications = !_showAllModifications;
        });
      },
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required bool showAll,
    required int totalCount,
    required VoidCallback onToggle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color, fontSize: 16)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (totalCount > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(showAll ? Icons.expand_less : Icons.expand_more),
                  label: Text(
                      showAll ? 'Show Less' : 'Show ${totalCount - 3} More'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekByWeekBreakdown() {
    // Parse week range (e.g., "1-4" or "5-8")
    final weekRange =
        widget.phase.weekRange.toLowerCase().replaceAll('weeks', '').trim();
    final parts = weekRange.split('-');
    final startWeek = int.tryParse(parts[0]) ?? 1;
    final endWeek =
        int.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? startWeek;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.calendar_today, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  '📅 Week-by-Week Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(endWeek - startWeek + 1, (index) {
              final weekNumber = startWeek + index;
              return _buildWeekCard(weekNumber);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCard(int weekNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPhaseColor(widget.phaseNumber),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Week $weekNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => _addWeekNote(weekNumber),
                tooltip: 'Add Note',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getWeekFocus(weekNumber),
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _viewExercises,
          icon: const Icon(Icons.fitness_center),
          label: const Text('View Phase Exercises'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getPhaseColor(widget.phaseNumber),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _trackProgress,
          icon: const Icon(Icons.timeline),
          label: const Text('Track My Progress'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Color _getPhaseColor(int phaseNumber) {
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

  IconData _getPhaseIcon(int phaseNumber) {
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

  String _getWeekFocus(int weekNumber) {
    // Provide general guidance based on week number and phase
    final weekInPhase = weekNumber % 4;

    switch (widget.phaseNumber) {
      case 1:
        switch (weekInPhase) {
          case 1:
            return 'Focus: Baseline assessment and mobility introduction';
          case 2:
            return 'Focus: Establish daily mobility routine and movement patterns';
          case 3:
            return 'Focus: Increase exercise volume, monitor pain response';
          case 0:
            return 'Focus: Consolidate gains, prepare for next phase';
          default:
            return 'Focus: Continue building foundation';
        }
      case 2:
        switch (weekInPhase) {
          case 1:
            return 'Focus: Introduction to resistance training';
          case 2:
            return 'Focus: Progressive loading and volume increase';
          case 3:
            return 'Focus: Integrate exercises with running';
          case 0:
            return 'Focus: Test improvements, adjust intensity';
          default:
            return 'Focus: Build functional strength';
        }
      case 3:
        switch (weekInPhase) {
          case 1:
            return 'Focus: Plyometric introduction and power work';
          case 2:
            return 'Focus: Speed work reintroduction';
          case 3:
            return 'Focus: High-intensity training integration';
          case 0:
            return 'Focus: Performance testing and assessment';
          default:
            return 'Focus: Restore performance capacity';
        }
      case 4:
        return 'Focus: Maintenance routine and performance optimization';
      default:
        return 'Focus: Follow phase guidelines';
    }
  }

  void _addWeekNote(int weekNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Week $weekNumber Note'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Add your notes or observations...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save note
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note saved!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _viewExercises() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.phase.phaseName} Exercises'),
        content: const Text(
          'Exercise library for this phase will be displayed here.\n\n'
          'This feature is coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _trackProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress tracking coming soon!')),
    );
  }
}
