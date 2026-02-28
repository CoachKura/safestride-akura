// lib/screens/kura_coach_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'kura_coach_workout_detail_screen.dart';

class KuraCoachCalendarScreen extends StatefulWidget {
  const KuraCoachCalendarScreen({super.key});

  @override
  State<KuraCoachCalendarScreen> createState() =>
      _KuraCoachCalendarScreenState();
}

class _KuraCoachCalendarScreenState extends State<KuraCoachCalendarScreen> {
  final _supabase = Supabase.instance.client;
  DateTime _selectedWeekStart = DateTime.now();
  List<Map<String, dynamic>> _weekWorkouts = [];
  bool _loading = true;
  int _currentWeek = 1;
  final int _totalWeeks = 4;

  // Zone colors matching AISRI methodology
  static const Map<String, Color> _zoneColors = {
    'AR': Color(0xFF2196F3), // Blue - Active Recovery
    'F': Color(0xFF00BCD4), // Cyan - Foundation
    'EN': Color(0xFF009688), // Teal - Endurance
    'TH': Color(0xFFFF9800), // Orange - Threshold
    'P': Color(0xFFF44336), // Red - Performance
    'SP': Color(0xFF9C27B0), // Purple - Speed
  };

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = _getWeekStart(DateTime.now());
    _loadWeekWorkouts();
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the current week
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadWeekWorkouts() async {
    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final weekEnd = _selectedWeekStart.add(const Duration(days: 7));

      final response = await _supabase
          .from('ai_workouts')
          .select('*, ai_workout_plans!inner(user_id)')
          .eq('ai_workout_plans.user_id', userId)
          .gte('workout_date',
              _selectedWeekStart.toIso8601String().split('T')[0])
          .lt('workout_date', weekEnd.toIso8601String().split('T')[0])
          .order('workout_date');

      // Calculate which week we're viewing (1-4)
      final now = DateTime.now();
      final firstWorkoutDate = _selectedWeekStart;
      _currentWeek =
          ((now.difference(firstWorkoutDate).inDays / 7).floor() % 4) + 1;

      setState(() {
        _weekWorkouts = (response as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading workouts: $e')),
        );
      }
    }
  }

  void _previousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
    _loadWeekWorkouts();
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    });
    _loadWeekWorkouts();
  }

  void _goToToday() {
    setState(() {
      _selectedWeekStart = _getWeekStart(DateTime.now());
    });
    _loadWeekWorkouts();
  }

  Color _getZoneColor(String? zone) {
    if (zone == null) return Colors.grey;
    final zoneKey = zone.split('-')[0].trim().toUpperCase();
    return _zoneColors[zoneKey] ?? Colors.grey;
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return '✅';
      case 'skipped':
        return '⏭️';
      case 'scheduled':
      default:
        return '📅';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 8),
            Text('Kura Coach Calendar'),
          ],
        ),
        backgroundColor: const Color(0xFF00D9FF),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Week Header Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00D9FF), Color(0xFF0099CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Week Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousWeek,
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 32),
                    ),
                    Column(
                      children: [
                        Text(
                          'Week $_currentWeek of $_totalWeeks',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM d').format(_selectedWeekStart)} - ${DateFormat('MMM d, yyyy').format(_selectedWeekStart.add(const Duration(days: 6)))}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _nextWeek,
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Today Button
                ElevatedButton.icon(
                  onPressed: _goToToday,
                  icon: const Icon(Icons.today, size: 18),
                  label: const Text('Today'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0099CC),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Calendar Grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _weekWorkouts.isEmpty
                    ? _buildEmptyState()
                    : _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Workouts Scheduled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your goals form to generate your personalized 4-week training plan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.flag),
              label: const Text('Set Goals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Week Days
        for (int i = 0; i < 7; i++) _buildDayCard(i),
      ],
    );
  }

  Widget _buildDayCard(int dayOffset) {
    final date = _selectedWeekStart.add(Duration(days: dayOffset));
    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    // Find workout for this day
    final workout = _weekWorkouts.where((w) {
      final workoutDate = DateTime.parse(w['workout_date']);
      return workoutDate.year == date.year &&
          workoutDate.month == date.month &&
          workoutDate.day == date.day;
    }).firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: workout != null ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isToday
            ? const BorderSide(color: Color(0xFF00D9FF), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: workout != null
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KuraCoachWorkoutDetailScreen(
                      workoutId: workout['id'],
                    ),
                  ),
                ).then((_) => _loadWeekWorkouts())
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date Badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color(0xFF00D9FF)
                      : workout != null
                          ? _getZoneColor(workout['zone'])
                              .withValues(alpha: 0.1)
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : Colors.grey[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Workout Info
              Expanded(
                child: workout != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Zone Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getZoneColor(workout['zone']),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  workout['zone'] ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getStatusIcon(workout['status']),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            workout['workout_name'] ?? 'Workout',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${workout['duration_minutes']} min',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.straighten,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${workout['estimated_distance']?.toStringAsFixed(1) ?? '0.0'} km',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Text(
                        'Rest Day',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),

              // Arrow
              if (workout != null)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
