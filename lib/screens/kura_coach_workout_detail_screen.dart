// lib/screens/kura_coach_workout_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class KuraCoachWorkoutDetailScreen extends StatefulWidget {
  final int workoutId;

  const KuraCoachWorkoutDetailScreen({
    super.key,
    required this.workoutId,
  });

  @override
  State<KuraCoachWorkoutDetailScreen> createState() =>
      _KuraCoachWorkoutDetailScreenState();
}

class _KuraCoachWorkoutDetailScreenState
    extends State<KuraCoachWorkoutDetailScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _workout;
  bool _loading = true;

  // Zone colors matching calendar
  static const Map<String, Color> _zoneColors = {
    'AR': Color(0xFF2196F3),  // Blue
    'F': Color(0xFF00BCD4),   // Cyan
    'EN': Color(0xFF009688),  // Teal
    'TH': Color(0xFFFF9800),  // Orange
    'P': Color(0xFFF44336),   // Red
    'SP': Color(0xFF9C27B0),  // Purple
  };

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    try {
      final response = await _supabase
          .from('ai_workouts')
          .select()
          .eq('id', widget.workoutId)
          .single();

      setState(() {
        _workout = response;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workout: $e')),
        );
      }
    }
  }

  Color _getZoneColor() {
    if (_workout == null) return Colors.grey;
    final zone = _workout!['zone'] as String?;
    if (zone == null) return Colors.grey;
    final zoneKey = zone.split('-')[0].trim().toUpperCase();
    return _zoneColors[zoneKey] ?? Colors.grey;
  }

  Future<void> _markComplete() async {
    try {
      await _supabase
          .from('ai_workouts')
          .update({'status': 'completed'})
          .eq('id', widget.workoutId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Workout marked as complete!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showGarminInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _buildGarminInstructions(scrollController),
      ),
    );
  }

  Widget _buildGarminInstructions(ScrollController scrollController) {
    if (_workout == null) return const SizedBox();

    final zone = _workout!['zone'] ?? 'N/A';
    final structure = _workout!['workout_structure'] as Map<String, dynamic>? ?? {};
    final warmup = structure['warmup'] as Map<String, dynamic>? ?? {};
    final intervals = structure['intervals'] as List? ?? [];
    final cooldown = structure['cooldown'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Icon(Icons.watch, size: 32, color: _getZoneColor()),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Create in Garmin Connect',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Step 1: Open Garmin Connect
          _buildInstructionStep(
            '1',
            'Open Garmin Connect App',
            'Tap More → Training → Workouts → Create a Workout',
            Icons.phone_android,
          ),

          // Step 2: Workout Name
          _buildInstructionStep(
            '2',
            'Name Your Workout',
            'Enter: "${_workout!['workout_name']}"',
            Icons.edit,
          ),

          // Step 3: Add Warmup
          _buildInstructionStep(
            '3',
            'Add Warmup',
            'Type: Warmup\nDuration: ${warmup['duration_minutes'] ?? 10} minutes\nTarget: HR Zone ${warmup['zone'] ?? 'AR'} (${warmup['hr_range'] ?? '108-120 bpm'})',
            Icons.wb_sunny,
          ),

          // Step 4: Add Intervals
          if (intervals.isNotEmpty)
            _buildInstructionStep(
              '4',
              'Add Interval Repeat Block',
              'Repeat: ${intervals.length} times\n\n' +
                  intervals.map((interval) {
                    final work = interval['work'] as Map<String, dynamic>? ?? {};
                    final rest = interval['rest'] as Map<String, dynamic>? ?? {};
                    return '→ Work: ${work['duration_minutes']} min (HR ${work['hr_range']})\n' +
                        '→ Rest: ${rest['duration_minutes']} min (HR ${rest['hr_range']})';
                  }).join('\n\n'),
              Icons.repeat,
            ),

          // Step 5: Add Cooldown
          _buildInstructionStep(
            '5',
            'Add Cooldown',
            'Type: Cooldown\nDuration: ${cooldown['duration_minutes'] ?? 5} minutes\nTarget: HR Zone ${cooldown['zone'] ?? 'AR'} (${cooldown['hr_range'] ?? '108-120 bpm'})',
            Icons.nightlight,
          ),

          // Step 6: Save & Sync
          _buildInstructionStep(
            '6',
            'Save & Sync to Watch',
            'Tap Save → Pull down to sync → Workout appears on your watch!',
            Icons.sync,
          ),

          const SizedBox(height: 24),

          // Quick Reference Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getZoneColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getZoneColor(), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: _getZoneColor()),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Reference',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getZoneColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Zone: $zone\n'
                  'Total Time: ${_workout!['duration_minutes']} minutes\n'
                  'Distance: ${_workout!['estimated_distance']?.toStringAsFixed(1)} km\n'
                  'Max HR: ${_workout!['target_hr_max']} bpm',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Close Button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getZoneColor(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Got It!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getZoneColor(),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: _getZoneColor()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Details')),
        body: const Center(child: Text('Workout not found')),
      );
    }

    final scheduledDate = DateTime.parse(_workout!['workout_date']);
    final status = _workout!['status'] as String? ?? 'scheduled';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Workout Details'),
        backgroundColor: _getZoneColor(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getZoneColor(), _getZoneColor().withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zone Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _workout!['zone'] ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Workout Name
                  Text(
                    _workout!['workout_name'] ?? 'Workout',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(scheduledDate),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Workout Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      Icons.timer,
                      '${_workout!['duration_minutes']} min',
                      'Duration',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      Icons.straighten,
                      '${_workout!['estimated_distance']?.toStringAsFixed(1) ?? '0.0'} km',
                      'Distance',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      Icons.favorite,
                      '${_workout!['target_hr_max']} bpm',
                      'Max HR',
                    ),
                  ),
                ],
              ),
            ),

            // Workout Structure
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.playlist_play, color: _getZoneColor()),
                          const SizedBox(width: 8),
                          const Text(
                            'Workout Structure',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWorkoutTimeline(),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Create in Garmin Button
                  ElevatedButton.icon(
                    onPressed: _showGarminInstructions,
                    icon: const Icon(Icons.watch),
                    label: const Text('Create in Garmin Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getZoneColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mark Complete Button (if not completed)
                  if (status != 'completed')
                    OutlinedButton.icon(
                      onPressed: _markComplete,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Complete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  // Completed Badge
                  if (status == 'completed')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Completed ✅',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: _getZoneColor(), size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTimeline() {
    final structure = _workout!['workout_structure'] as Map<String, dynamic>? ?? {};
    final warmup = structure['warmup'] as Map<String, dynamic>? ?? {};
    final intervals = structure['intervals'] as List? ?? [];
    final cooldown = structure['cooldown'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // Warmup
        _buildTimelineItem(
          'Warmup',
          '${warmup['duration_minutes'] ?? 10} min',
          warmup['zone'] ?? 'AR',
          warmup['hr_range'] ?? 'N/A',
          Colors.blue[300]!,
        ),
        // Intervals
        if (intervals.isNotEmpty) ...[
          _buildTimelineDivider('${intervals.length}× Repeat'),
          ...intervals.asMap().entries.map((entry) {
            final interval = entry.value as Map<String, dynamic>;
            final work = interval['work'] as Map<String, dynamic>? ?? {};
            final rest = interval['rest'] as Map<String, dynamic>? ?? {};
            return Column(
              children: [
                _buildTimelineItem(
                  'Work',
                  '${work['duration_minutes']} min',
                  work['zone'] ?? 'TH',
                  work['hr_range'] ?? 'N/A',
                  _getZoneColor(),
                ),
                _buildTimelineItem(
                  'Rest',
                  '${rest['duration_minutes']} min',
                  rest['zone'] ?? 'F',
                  rest['hr_range'] ?? 'N/A',
                  Colors.cyan[300]!,
                ),
              ],
            );
          }),
        ],
        // Cooldown
        _buildTimelineItem(
          'Cooldown',
          '${cooldown['duration_minutes'] ?? 5} min',
          cooldown['zone'] ?? 'AR',
          cooldown['hr_range'] ?? 'N/A',
          Colors.blue[300]!,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String duration,
    String zone,
    String hrRange,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Bar
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Zone $zone • $hrRange',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[400])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[400])),
        ],
      ),
    );
  }
}
