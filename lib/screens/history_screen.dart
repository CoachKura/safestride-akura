import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> workouts = [];
  int totalWorkouts = 0;
  double totalDistance = 0.0;
  int totalMinutes = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('workouts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        workouts = List<Map<String, dynamic>>.from(response);
        totalWorkouts = workouts.length;
        totalDistance = workouts.fold(
            0.0, (sum, w) => sum + ((w['distance'] ?? 0.0) as num).toDouble());
        totalMinutes =
            workouts.fold(0, (sum, w) => sum + ((w['duration'] ?? 0) as int));
        isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading workouts: $e');
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredWorkouts {
    if (_selectedFilter == 'All') return workouts;
    if (_selectedFilter == 'Runs') {
      return workouts
          .where((w) =>
              (w['activity_type'] as String).toLowerCase().contains('run'))
          .toList();
    }
    return workouts
        .where((w) =>
            !(w['activity_type'] as String).toLowerCase().contains('run'))
        .toList();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final workoutDate = DateTime(date.year, date.month, date.day);

      if (workoutDate == today) return 'Today';
      if (workoutDate == yesterday) return 'Yesterday';
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Period
                    Center(
                      child: Text(
                        'Last 30 days',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Stats Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          value: totalWorkouts.toString(),
                          label: 'Workouts',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          value: totalDistance.toStringAsFixed(1),
                          label: 'Total km',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          value: (totalMinutes / 60).toStringAsFixed(1),
                          label: 'Hours',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filter Tabs
                  Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        icon: Icons.apps,
                        isSelected: _selectedFilter == 'All',
                        onTap: () => setState(() => _selectedFilter = 'All'),
                      ),
                      const SizedBox(width: 12),
                      _FilterChip(
                        label: 'Runs',
                        icon: Icons.directions_run,
                        isSelected: _selectedFilter == 'Runs',
                        onTap: () => setState(() => _selectedFilter = 'Runs'),
                      ),
                      const SizedBox(width: 12),
                      _FilterChip(
                        label: 'Other',
                        icon: Icons.fitness_center,
                        isSelected: _selectedFilter == 'Other',
                        onTap: () => setState(() => _selectedFilter = 'Other'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Workout List
                  if (filteredWorkouts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.fitness_center,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No workouts yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start tracking your workouts!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredWorkouts.map((workout) => _WorkoutCard(
                          type: workout['activity_type'] ?? 'Workout',
                          date: _formatDate(workout['created_at']),
                          distance:
                              '${(workout['distance'] ?? 0.0).toStringAsFixed(1)} km',
                          duration: '${workout['duration'] ?? 0} min',
                          rpe: workout['rpe'] ?? 5,
                        )),
                ],
              ),
            ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String type;
  final String date;
  final String distance;
  final String duration;
  final int rpe;

  const _WorkoutCard({
    required this.type,
    required this.date,
    required this.distance,
    required this.duration,
    required this.rpe,
  });

  Color _getRPEColor(int rpe) {
    if (rpe <= 4) return Colors.green;
    if (rpe <= 6) return Colors.yellow.shade700;
    if (rpe <= 8) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$distance • $duration',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getRPEColor(rpe),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'RPE $rpe',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
