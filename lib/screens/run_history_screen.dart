// Run History Screen
// Display all past running sessions with stats and filtering

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/run_session.dart';
import '../services/run_session_service.dart';
import '../theme/app_colors.dart';

class RunHistoryScreen extends StatefulWidget {
  const RunHistoryScreen({Key? key}) : super(key: key);

  @override
  State<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends State<RunHistoryScreen> {
  final _supabase = Supabase.instance.client;
  List<RunSession> _sessions = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, easy, tempo, interval, long

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final sessions = await RunSessionService.loadUserSessions(
          userId: userId,
          limit: 100,
        );
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading runs: $e')),
        );
      }
    }
  }

  List<RunSession> get _filteredSessions {
    if (_filterType == 'all') {
      return _sessions;
    }
    return _sessions.where((s) {
      final type = s.workoutType?.toLowerCase() ?? '';
      return type.contains(_filterType);
    }).toList();
  }

  // Calculate weekly stats
  Map<String, dynamic> get _weeklyStats {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekSessions = _sessions.where((s) {
      return s.startTime.isAfter(weekStart);
    }).toList();

    final totalDistance = weekSessions.fold<double>(
      0.0,
      (sum, s) => sum + (s.distanceMeters / 1000),
    );
    final totalDuration = weekSessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );

    return {
      'count': weekSessions.length,
      'distance': totalDistance,
      'duration': totalDuration,
    };
  }

  Color _getWorkoutColor(String? type) {
    if (type == null) return Colors.grey;
    final typeStr = type.toLowerCase();
    if (typeStr.contains('interval')) return Colors.orange[700]!;
    if (typeStr.contains('tempo')) return Colors.amber[700]!;
    if (typeStr.contains('long')) return Colors.purple[700]!;
    if (typeStr.contains('easy')) return Colors.blue[600]!;
    return Colors.grey[700]!;
  }

  IconData _getWorkoutIcon(String? type) {
    if (type == null) return Icons.directions_run;
    final typeStr = type.toLowerCase();
    if (typeStr.contains('interval')) return Icons.speed;
    if (typeStr.contains('tempo')) return Icons.trending_up;
    if (typeStr.contains('long')) return Icons.hourglass_bottom;
    if (typeStr.contains('easy')) return Icons.self_improvement;
    return Icons.directions_run;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _weeklyStats;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Run History', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryOrange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Weekly stats summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange,
                          AppColors.accentGreen
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This Week',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              icon: Icons.fitness_center,
                              label: 'Runs',
                              value: '${stats['count']}',
                            ),
                            _buildStatCard(
                              icon: Icons.route,
                              label: 'Distance',
                              value:
                                  '${stats['distance'].toStringAsFixed(1)} km',
                            ),
                            _buildStatCard(
                              icon: Icons.timer,
                              label: 'Time',
                              value: RunSessionService.formatDuration(
                                stats['duration'],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Filter chips
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Easy', 'easy'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Tempo', 'tempo'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Interval', 'interval'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Long Run', 'long'),
                        ],
                      ),
                    ),
                  ),

                  // Runs list
                  Expanded(
                    child: _filteredSessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_run,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No runs yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start your first run from the training plan!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredSessions.length,
                            itemBuilder: (context, index) {
                              final session = _filteredSessions[index];
                              return _buildRunCard(session);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
        });
      },
      selectedColor: AppColors.primaryOrange.withOpacity(0.2),
      checkmarkColor: AppColors.primaryOrange,
    );
  }

  Widget _buildRunCard(RunSession session) {
    final workoutColor = _getWorkoutColor(session.workoutType);
    final workoutIcon = _getWorkoutIcon(session.workoutType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to run detail screen (reuse RunCompleteScreen)
          Navigator.pushNamed(
            context,
            '/run-complete',
            arguments: session,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Workout type indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: workoutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  workoutIcon,
                  color: workoutColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Run details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.workoutName ?? 'Free Run',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(session.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.route, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          RunSessionService.formatDistance(
                            session.distanceMeters,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          RunSessionService.formatDuration(
                            session.durationSeconds,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.speed, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          session.avgPaceMinPerKm != null &&
                                  session.avgPaceMinPerKm! > 0
                              ? RunSessionService.formatPace(
                                  session.avgPaceMinPerKm!,
                                )
                              : '--',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today at ${_formatTime(date)}';
    } else if (dateDay == yesterday) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      final weekday =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      final month = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][date.month - 1];
      return '$weekday, $month ${date.day} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
