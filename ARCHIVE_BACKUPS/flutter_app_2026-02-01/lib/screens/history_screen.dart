import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> workouts = [];
  bool isLoading = true;
  String filterType = 'All';
  String sortBy = 'date_desc';

  final List<String> activityTypes = ['All', 'Run', 'Walk', 'Cycling', 'Strength', 'Yoga'];
  final List<String> sortOptions = [
    'date_desc',
    'date_asc',
    'distance_desc',
    'distance_asc',
  ];

  final Map<String, IconData> activityIcons = {
    'Run': Icons.directions_run,
    'Walk': Icons.directions_walk,
    'Cycling': Icons.directions_bike,
    'Strength': Icons.fitness_center,
    'Yoga': Icons.self_improvement,
  };

  final Map<String, Color> activityColors = {
    'Run': Colors.blue,
    'Walk': Colors.green,
    'Cycling': Colors.orange,
    'Strength': Colors.red,
    'Yoga': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await SupabaseService.getWorkoutHistory();
      setState(() {
        workouts = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error loading history: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredWorkouts {
    var filtered = workouts;

    // Filter by type
    if (filterType != 'All') {
      filtered = filtered.where((w) => w['activity_type'] == filterType).toList();
    }

    // Sort
    switch (sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => DateTime.parse(b['activity_date'])
            .compareTo(DateTime.parse(a['activity_date'])));
        break;
      case 'date_asc':
        filtered.sort((a, b) => DateTime.parse(a['activity_date'])
            .compareTo(DateTime.parse(b['activity_date'])));
        break;
      case 'distance_desc':
        filtered.sort((a, b) => (b['distance_km'] ?? 0).compareTo(a['distance_km'] ?? 0));
        break;
      case 'distance_asc':
        filtered.sort((a, b) => (a['distance_km'] ?? 0).compareTo(b['distance_km'] ?? 0));
        break;
    }

    return filtered;
  }

  Map<String, dynamic> get statistics {
    final filtered = filteredWorkouts;
    if (filtered.isEmpty) {
      return {
        'total_workouts': 0,
        'total_distance': 0.0,
        'total_duration': 0,
        'avg_distance': 0.0,
      };
    }

    double totalDistance = 0;
    int totalDuration = 0;

    for (var workout in filtered) {
      totalDistance += (workout['distance_km'] as num?)?.toDouble() ?? 0;
      totalDuration += (workout['duration_minutes'] as int?) ?? 0;
    }

    return {
      'total_workouts': filtered.length,
      'total_distance': totalDistance,
      'total_duration': totalDuration,
      'avg_distance': totalDistance / filtered.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = statistics;
    final filtered = filteredWorkouts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkouts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Statistics Summary
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Workouts',
                          stats['total_workouts'].toString(),
                          Icons.fitness_center,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Distance',
                          '${stats['total_distance'].toStringAsFixed(1)} km',
                          Icons.straighten,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Duration',
                          '${(stats['total_duration'] / 60).toStringAsFixed(1)} hr',
                          Icons.timer,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Avg Distance',
                          '${stats['avg_distance'].toStringAsFixed(1)} km',
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filters
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Activity Type Filter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButton<String>(
                        value: filterType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.filter_list, size: 20),
                        items: activityTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  type == 'All' ? Icons.all_inclusive : activityIcons[type],
                                  size: 18,
                                  color: type == 'All' ? Colors.grey : activityColors[type],
                                ),
                                const SizedBox(width: 8),
                                Text(type, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            filterType = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Sort Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButton<String>(
                        value: sortBy,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.sort, size: 20),
                        items: const [
                          DropdownMenuItem(value: 'date_desc', child: Text('Latest First', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 'date_asc', child: Text('Oldest First', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 'distance_desc', child: Text('Longest First', style: TextStyle(fontSize: 14))),
                          DropdownMenuItem(value: 'distance_asc', child: Text('Shortest First', style: TextStyle(fontSize: 14))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            sortBy = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Workout List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                filterType == 'All'
                                    ? 'No workouts yet.\nStart tracking to see your history!'
                                    : 'No $filterType activities found.\nTry a different filter.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadWorkouts,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final workout = filtered[index];
                              return _buildWorkoutCard(workout);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final date = DateTime.parse(workout['activity_date']);
    final formattedDate = DateFormat('EEE, MMM d, y').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);
    final activityType = workout['activity_type'] ?? 'Run';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showWorkoutDetails(workout);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (activityColors[activityType] ?? Colors.blue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activityIcons[activityType] ?? Icons.directions_run,
                        color: activityColors[activityType] ?? Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activityType,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (workout['rpe'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRPEColor(workout['rpe']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: _getRPEColor(workout['rpe']),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${workout['rpe']}/10',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _getRPEColor(workout['rpe']),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStat(
                      Icons.straighten,
                      '${workout['distance_km']?.toStringAsFixed(2) ?? '0'} km',
                      Colors.blue,
                    ),
                    const SizedBox(width: 24),
                    _buildStat(
                      Icons.timer,
                      '${workout['duration_minutes'] ?? 0} min',
                      Colors.green,
                    ),
                    if (workout['avg_pace'] != null) ...[
                      const SizedBox(width: 24),
                      _buildStat(
                        Icons.speed,
                        workout['avg_pace'],
                        Colors.orange,
                      ),
                    ],
                  ],
                ),
                if (workout['notes'] != null && workout['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            workout['notes'],
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getRPEColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 5) return Colors.blue;
    if (rpe <= 7) return Colors.orange;
    return Colors.red;
  }

  void _showWorkoutDetails(Map<String, dynamic> workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final date = DateTime.parse(workout['activity_date']);
        final formattedDate = DateFormat('EEEE, MMMM d, y').format(date);
        final formattedTime = DateFormat('h:mm a').format(date);
        final activityType = workout['activity_type'] ?? 'Run';

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (activityColors[activityType] ?? Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      activityIcons[activityType] ?? Icons.directions_run,
                      color: activityColors[activityType] ?? Colors.blue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activityType,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Distance', '${workout['distance_km']?.toStringAsFixed(2) ?? '0'} km', Icons.straighten),
              _buildDetailRow('Duration', '${workout['duration_minutes'] ?? 0} minutes', Icons.timer),
              if (workout['avg_pace'] != null)
                _buildDetailRow('Average Pace', workout['avg_pace'], Icons.speed),
              if (workout['rpe'] != null)
                _buildDetailRow('RPE', '${workout['rpe']}/10', Icons.favorite),
              if (workout['notes'] != null && workout['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    workout['notes'],
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
