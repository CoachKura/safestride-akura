// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<Map<String, dynamic>> _workouts = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, running, strength, other
  String _sortBy =
      'date_desc'; // date_desc, date_asc, distance_desc, duration_desc

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch GPS activities (runs)
      final gpsQuery = Supabase.instance.client
          .from('gps_activities')
          .select(
              'id, start_time, duration_seconds, distance_meters, activity_type, avg_heart_rate, max_heart_rate, calories_burned')
          .eq('user_id', userId)
          .order('start_time', ascending: false);

      final gpsData = await gpsQuery;

      // Fetch manual workouts
      final workoutsQuery = Supabase.instance.client
          .from('workouts')
          .select(
              'id, created_at, duration_minutes, distance, distance_km, workout_type, notes')
          .or('user_id.eq.$userId,athlete_id.eq.$userId')
          .order('created_at', ascending: false);

      final workoutsData = await workoutsQuery;

      // Combine both sources
      List<Map<String, dynamic>> combined = [];

      // Add GPS activities
      for (var activity in gpsData) {
        combined.add({
          'id': 'gps_${activity['id']}',
          'source': 'gps',
          'date': DateTime.parse(activity['start_time']),
          'type': activity['activity_type'] ?? 'running',
          'duration': activity['duration_seconds'] / 60.0, // Convert to minutes
          'distance':
              (activity['distance_meters'] ?? 0) / 1000.0, // Convert to km
          'avgHr': activity['avg_heart_rate'],
          'maxHr': activity['max_heart_rate'],
          'calories': activity['calories_burned'],
        });
      }

      // Add manual workouts
      for (var workout in workoutsData) {
        final distance = workout['distance'] ?? workout['distance_km'] ?? 0.0;
        combined.add({
          'id': 'workout_${workout['id']}',
          'source': 'manual',
          'date': DateTime.parse(workout['created_at']),
          'type': workout['workout_type'] ?? 'other',
          'duration': (workout['duration_minutes'] ?? 0).toDouble(),
          'distance': distance.toDouble(),
          'notes': workout['notes'],
        });
      }

      setState(() {
        _workouts = combined;
        _isLoading = false;
      });

      _applySortAndFilter();
    } catch (e) {
      debugPrint('Error loading workouts: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applySortAndFilter() {
    setState(() {
      // Filter
      var filtered = _workouts.where((w) {
        if (_filterType == 'all') return true;
        if (_filterType == 'running') return w['type'] == 'running';
        if (_filterType == 'strength') return w['type'] == 'strength';
        return w['type'] != 'running' && w['type'] != 'strength';
      }).toList();

      // Sort
      filtered.sort((a, b) {
        switch (_sortBy) {
          case 'date_asc':
            return a['date'].compareTo(b['date']);
          case 'distance_desc':
            return (b['distance'] ?? 0.0).compareTo(a['distance'] ?? 0.0);
          case 'duration_desc':
            return (b['duration'] ?? 0.0).compareTo(a['duration'] ?? 0.0);
          case 'date_desc':
          default:
            return b['date'].compareTo(a['date']);
        }
      });

      _workouts = filtered;
    });
  }

  Future<void> _deleteWorkout(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (id.startsWith('gps_')) {
        final actualId = id.substring(4);
        await Supabase.instance.client
            .from('gps_activities')
            .delete()
            .eq('id', actualId);
      } else if (id.startsWith('workout_')) {
        final actualId = id.substring(8);
        await Supabase.instance.client
            .from('workouts')
            .delete()
            .eq('id', actualId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout deleted')),
        );
        _loadWorkouts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting workout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workouts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_run,
                          size: 80, color: Colors.grey[400]),
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
                        'Start tracking to see your history',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWorkouts,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                      ..._workouts.map((workout) => _buildWorkoutCard(workout)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final totalWorkouts = _workouts.length;
    final totalDistance =
        _workouts.fold(0.0, (sum, w) => sum + (w['distance'] ?? 0.0));
    final totalDuration =
        _workouts.fold(0.0, (sum, w) => sum + (w['duration'] ?? 0.0));
    final avgDistance = totalWorkouts > 0 ? totalDistance / totalWorkouts : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Workouts', '$totalWorkouts'),
              _buildSummaryItem(
                  'Distance', '${totalDistance.toStringAsFixed(1)} km'),
              _buildSummaryItem(
                  'Time', '${(totalDuration / 60).toStringAsFixed(1)} h'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Avg: ${avgDistance.toStringAsFixed(1)} km per workout',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final date = workout['date'] as DateTime;
    final type = workout['type'] as String;
    final duration = workout['duration'] as double;
    final distance = workout['distance'] as double?;
    final source = workout['source'] as String;

    IconData icon;
    Color color;

    switch (type) {
      case 'running':
        icon = Icons.directions_run;
        color = Colors.blue;
        break;
      case 'strength':
        icon = Icons.fitness_center;
        color = Colors.orange;
        break;
      default:
        icon = Icons.sports;
        color = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showWorkoutDetails(workout),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type[0].toUpperCase() + type.substring(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (source == 'gps')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'GPS',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(date),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (distance != null && distance > 0) ...[
                          Icon(Icons.straighten,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(2)} km',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${duration.toStringAsFixed(0)} min',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteWorkout(workout['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutDetails(Map<String, dynamic> workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workout Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Type', workout['type']),
              _buildDetailRow(
                  'Date', DateFormat('MMMM dd, yyyy').format(workout['date'])),
              _buildDetailRow(
                  'Time', DateFormat('HH:mm:ss').format(workout['date'])),
              _buildDetailRow('Duration',
                  '${workout['duration'].toStringAsFixed(0)} minutes'),
              if (workout['distance'] != null && workout['distance'] > 0)
                _buildDetailRow(
                    'Distance', '${workout['distance'].toStringAsFixed(2)} km'),
              if (workout['avgHr'] != null)
                _buildDetailRow('Avg Heart Rate', '${workout['avgHr']} bpm'),
              if (workout['maxHr'] != null)
                _buildDetailRow('Max Heart Rate', '${workout['maxHr']} bpm'),
              if (workout['calories'] != null)
                _buildDetailRow('Calories', '${workout['calories']} kcal'),
              if (workout['notes'] != null && workout['notes'].isNotEmpty)
                _buildDetailRow('Notes', workout['notes']),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteWorkout(workout['id']);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by type:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: const Text('All'),
              value: 'all',
              groupValue: _filterType,
              onChanged: (value) {
                setState(() => _filterType = value!);
                Navigator.pop(context);
                _loadWorkouts();
              },
            ),
            RadioListTile<String>(
              title: const Text('Running'),
              value: 'running',
              groupValue: _filterType,
              onChanged: (value) {
                setState(() => _filterType = value!);
                Navigator.pop(context);
                _loadWorkouts();
              },
            ),
            RadioListTile<String>(
              title: const Text('Strength'),
              value: 'strength',
              groupValue: _filterType,
              onChanged: (value) {
                setState(() => _filterType = value!);
                Navigator.pop(context);
                _loadWorkouts();
              },
            ),
            RadioListTile<String>(
              title: const Text('Other'),
              value: 'other',
              groupValue: _filterType,
              onChanged: (value) {
                setState(() => _filterType = value!);
                Navigator.pop(context);
                _loadWorkouts();
              },
            ),
            const SizedBox(height: 16),
            const Text('Sort by:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: const Text('Date (newest first)'),
              value: 'date_desc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
                _applySortAndFilter();
              },
            ),
            RadioListTile<String>(
              title: const Text('Date (oldest first)'),
              value: 'date_asc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
                _applySortAndFilter();
              },
            ),
            RadioListTile<String>(
              title: const Text('Distance'),
              value: 'distance_desc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
                _applySortAndFilter();
              },
            ),
            RadioListTile<String>(
              title: const Text('Duration'),
              value: 'duration_desc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
                _applySortAndFilter();
              },
            ),
          ],
        ),
      ),
    );
  }
}
