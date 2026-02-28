// Analytics Dashboard Screen
// Display performance metrics, trends, and personal bests

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/analytics_service.dart';
import '../services/run_session_service.dart';
import '../theme/app_colors.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  List<WeeklyData> _weeklyMileage = [];
  List<PaceTrend> _paceTrends = [];
  PersonalBests? _personalBests;
  List<TrainingLoad> _trainingLoad = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final results = await Future.wait([
          AnalyticsService.getWeeklyMileage(userId: userId, weeks: 12),
          AnalyticsService.getPaceTrends(userId: userId, months: 6),
          AnalyticsService.getPersonalBests(userId: userId),
          AnalyticsService.getTrainingLoad(userId: userId, weeks: 8),
        ]);

        setState(() {
          _weeklyMileage = results[0] as List<WeeklyData>;
          _paceTrends = results[1] as List<PaceTrend>;
          _personalBests = results[2] as PersonalBests;
          _trainingLoad = results[3] as List<TrainingLoad>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryOrange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Bests
                    _buildSectionTitle('Personal Bests', Icons.emoji_events),
                    const SizedBox(height: 12),
                    _buildPersonalBestsSection(),
                    const SizedBox(height: 24),

                    // Weekly Mileage Chart
                    _buildSectionTitle('Weekly Mileage', Icons.trending_up),
                    const SizedBox(height: 12),
                    _buildWeeklyMileageChart(),
                    const SizedBox(height: 24),

                    // Pace Trends
                    _buildSectionTitle('Pace Trends', Icons.speed),
                    const SizedBox(height: 12),
                    _buildPaceTrendsChart(),
                    const SizedBox(height: 24),

                    // Training Load
                    _buildSectionTitle('Training Load', Icons.fitness_center),
                    const SizedBox(height: 12),
                    _buildTrainingLoadChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalBestsSection() {
    final pbs = _personalBests;
    if (pbs == null) {
      return _buildEmptyState('No personal bests yet');
    }

    return Column(
      children: [
        if (pbs.fastest5k != null)
          _buildPBCard(
            title: 'Fastest 5K',
            icon: Icons.directions_run,
            time: RunSessionService.formatDuration(
                pbs.fastest5k!.durationSeconds),
            pace: RunSessionService.formatPace(pbs.fastest5k!.avgPaceMinPerKm),
            date: _formatDate(pbs.fastest5k!.startTime),
            color: Colors.blue,
          ),
        if (pbs.fastest10k != null)
          _buildPBCard(
            title: 'Fastest 10K',
            icon: Icons.directions_run,
            time: RunSessionService.formatDuration(
                pbs.fastest10k!.durationSeconds),
            pace: RunSessionService.formatPace(pbs.fastest10k!.avgPaceMinPerKm),
            date: _formatDate(pbs.fastest10k!.startTime),
            color: Colors.green,
          ),
        if (pbs.fastestHalfMarathon != null)
          _buildPBCard(
            title: 'Fastest Half Marathon',
            icon: Icons.directions_run,
            time: RunSessionService.formatDuration(
                pbs.fastestHalfMarathon!.durationSeconds),
            pace: RunSessionService.formatPace(
                pbs.fastestHalfMarathon!.avgPaceMinPerKm),
            date: _formatDate(pbs.fastestHalfMarathon!.startTime),
            color: Colors.orange,
          ),
        if (pbs.longestRun != null)
          _buildPBCard(
            title: 'Longest Run',
            icon: Icons.landscape,
            time: RunSessionService.formatDuration(
                pbs.longestRun!.durationSeconds),
            pace: RunSessionService.formatDistance(
                pbs.longestRun!.distanceMeters),
            date: _formatDate(pbs.longestRun!.startTime),
            color: Colors.purple,
          ),
        if (pbs.fastestPaceRun != null)
          _buildPBCard(
            title: 'Fastest Pace',
            icon: Icons.speed,
            time: RunSessionService.formatPace(
                pbs.fastestPaceRun!.avgPaceMinPerKm),
            pace: RunSessionService.formatDistance(
                pbs.fastestPaceRun!.distanceMeters),
            date: _formatDate(pbs.fastestPaceRun!.startTime),
            color: Colors.red,
          ),
        if (pbs.fastest5k == null &&
            pbs.fastest10k == null &&
            pbs.fastestHalfMarathon == null &&
            pbs.longestRun == null &&
            pbs.fastestPaceRun == null)
          _buildEmptyState('Complete more runs to see your personal bests!'),
      ],
    );
  }

  Widget _buildPBCard({
    required String title,
    required IconData icon,
    required String time,
    required String pace,
    required String date,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$time • $pace',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.emoji_events, color: Colors.amber[700], size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyMileageChart() {
    if (_weeklyMileage.isEmpty) {
      return _buildEmptyState('No weekly data available');
    }

    final maxDistance =
        _weeklyMileage.map((w) => w.distance).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _weeklyMileage.map((week) {
                  final heightRatio =
                      maxDistance > 0 ? (week.distance / maxDistance) : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Distance label
                          if (week.distance > 0)
                            Text(
                              week.distance.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          const SizedBox(height: 4),
                          // Bar
                          Container(
                            height: 150 * heightRatio,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryOrange,
                                  AppColors.accentGreen,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Week label
                          Text(
                            week.weekLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Distance (km) per week',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceTrendsChart() {
    if (_paceTrends.isEmpty) {
      return _buildEmptyState('No pace data available');
    }

    final maxPace = _paceTrends
        .map((p) => p.avgPaceMinPerKm)
        .reduce((a, b) => a > b ? a : b);
    final minPace = _paceTrends
        .map((p) => p.avgPaceMinPerKm)
        .reduce((a, b) => a < b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _paceTrends.map((trend) {
                  // Invert ratio since lower pace is better
                  final heightRatio = maxPace > minPace
                      ? 1 -
                          ((trend.avgPaceMinPerKm - minPace) /
                              (maxPace - minPace))
                      : 0.5;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Pace label
                          Text(
                            RunSessionService.formatPace(trend.avgPaceMinPerKm),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Bar
                          Container(
                            height: 120 + (30 * heightRatio),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange[700]!,
                                  Colors.amber[600]!,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Month label
                          Text(
                            trend.monthLabel.split(' ')[0],
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Average pace (min/km) per month',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingLoadChart() {
    if (_trainingLoad.isEmpty) {
      return _buildEmptyState('No training load data available');
    }

    final maxLoad =
        _trainingLoad.map((l) => l.load).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chart
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _trainingLoad.map((load) {
                  final heightRatio = maxLoad > 0 ? (load.load / maxLoad) : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Load label
                          if (load.load > 0)
                            Text(
                              load.load.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          const SizedBox(height: 4),
                          // Bar
                          Container(
                            height: 150 * heightRatio,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple[700]!,
                                  Colors.purple[400]!,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Week label
                          Text(
                            load.weekLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Training load per week',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '$month ${date.day}, ${date.year}';
  }
}
