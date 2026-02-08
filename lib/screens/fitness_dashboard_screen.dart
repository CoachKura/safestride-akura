// lib/screens/fitness_dashboard_screen.dart
// Garmin/Runkeeper-style dark-themed fitness dashboard

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_models.dart';
import '../theme/dashboard_colors.dart';
import '../widgets/circular_metric.dart';
import '../widgets/stat_card.dart';
import '../widgets/activity_bar_chart.dart';

class FitnessDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const FitnessDashboardScreen({super.key, this.onNavigate});

  @override
  State<FitnessDashboardScreen> createState() => _FitnessDashboardScreenState();
}

class _FitnessDashboardScreenState extends State<FitnessDashboardScreen> {
  bool _isLoading = true;
  FitnessDashboardData? _data;
  String? _errorMsg;
  DateTime _lastSyncTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        setState(() {
          _data = FitnessDashboardData.mock();
          _isLoading = false;
          _lastSyncTime = DateTime.now();
        });
        return;
      }

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));

      final weeklyResponse = await Supabase.instance.client
          .from('gps_activities')
          .select(
              'distance_meters, calories, duration_seconds, start_time, avg_heart_rate')
          .eq('user_id', userId)
          .gte('start_time', weekAgo.toIso8601String())
          .order('start_time', ascending: true);

      final monthlyResponse = await Supabase.instance.client
          .from('gps_activities')
          .select('distance_meters, start_time')
          .eq('user_id', userId)
          .gte('start_time', monthAgo.toIso8601String())
          .order('start_time', ascending: true);

      final todayStats = _calculateTodayStats(weeklyResponse);
      final weeklyStats = _calculateWeeklyStats(weeklyResponse);
      final monthlyChart = _buildMonthlyChart(monthlyResponse);
      final streak = _calculateStreak(weeklyResponse);

      setState(() {
        _data = FitnessDashboardData(
          steps: ((todayStats['distance'] as double) * 1312).round(),
          stepsGoal: 10000,
          distance: todayStats['distance'] as double,
          distanceGoal: 10.0,
          calories: todayStats['calories'] as int,
          caloriesGoal: 2000,
          activeCalories: todayStats['calories'] as int,
          activitiesCount: weeklyStats['count'] as int,
          caloriesRemaining: 2000 - (todayStats['calories'] as int),
          caloriesConsumed: 0,
          monthlyActivities: monthlyChart,
          weeklySteps: _buildWeeklySteps(weeklyResponse),
          activeDuration: Duration(seconds: todayStats['duration'] as int),
          currentStreak: streak,
          avgHeartRate: todayStats['hr'] as double,
        );
        _isLoading = false;
        _lastSyncTime = DateTime.now();
      });
    } catch (e) {
      debugPrint('Error loading fitness dashboard: $e');
      setState(() {
        _errorMsg = e.toString();
        _data = FitnessDashboardData.mock();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateTodayStats(List<dynamic> activities) {
    final today = DateTime.now();
    double distance = 0;
    int calories = 0;
    int duration = 0;
    double hr = 0;
    int hrCount = 0;

    for (var activity in activities) {
      final startTime = DateTime.parse(activity['start_time'] as String);
      if (startTime.day == today.day &&
          startTime.month == today.month &&
          startTime.year == today.year) {
        distance += ((activity['distance_meters'] as num?) ?? 0) / 1000;
        calories += (activity['calories'] as int?) ?? 0;
        duration += (activity['duration_seconds'] as int?) ?? 0;
        if (activity['avg_heart_rate'] != null) {
          hr += (activity['avg_heart_rate'] as num).toDouble();
          hrCount++;
        }
      }
    }

    return {
      'distance': distance,
      'calories': calories,
      'duration': duration,
      'hr': hrCount > 0 ? hr / hrCount : 0.0,
    };
  }

  Map<String, dynamic> _calculateWeeklyStats(List<dynamic> activities) {
    double distance = 0;
    int calories = 0;
    int count = activities.length;

    for (var activity in activities) {
      distance += ((activity['distance_meters'] as num?) ?? 0) / 1000;
      calories += (activity['calories'] as int?) ?? 0;
    }

    return {
      'distance': distance,
      'calories': calories,
      'count': count,
    };
  }

  List<double> _buildMonthlyChart(List<dynamic> activities) {
    final chart = List<double>.filled(30, 0);
    final now = DateTime.now();

    for (var activity in activities) {
      final startTime = DateTime.parse(activity['start_time'] as String);
      final daysAgo = now.difference(startTime).inDays;
      if (daysAgo >= 0 && daysAgo < 30) {
        chart[29 - daysAgo] +=
            ((activity['distance_meters'] as num?) ?? 0) / 1000;
      }
    }

    return chart;
  }

  List<double> _buildWeeklySteps(List<dynamic> activities) {
    final steps = List<double>.filled(7, 0);
    final now = DateTime.now();

    for (var activity in activities) {
      final startTime = DateTime.parse(activity['start_time'] as String);
      final daysAgo = now.difference(startTime).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        steps[6 - daysAgo] +=
            ((activity['distance_meters'] as num?) ?? 0) * 1.312;
      }
    }

    return steps;
  }

  int _calculateStreak(List<dynamic> activities) {
    if (activities.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    final activityDays = <DateTime>{};
    for (var activity in activities) {
      final date = DateTime.parse(activity['start_time'] as String);
      activityDays.add(DateTime(date.year, date.month, date.day));
    }

    while (activityDays.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.screenBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF667EEA),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: const Color(0xFF667EEA),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      if (_errorMsg != null) _buildErrorBanner(),
                      const SizedBox(height: 24),
                      _buildCircularMetrics(),
                      const SizedBox(height: 24),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      _buildActivityChart(),
                      const SizedBox(height: 24),
                      _buildWeeklyChart(),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Using cached data - live refresh failed',
              style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Day',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadDashboardData,
            ),
            Text(
              'Last sync: ${_formatTime(_lastSyncTime)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularMetrics() {
    if (_data == null) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircularMetric(
          value: _data!.steps.toDouble(),
          goal: _data!.stepsGoal.toDouble(),
          label: 'Steps',
          colors: DashboardColors.stepsGradient,
          size: 100,
        ),
        CircularMetric(
          value: _data!.distance,
          goal: _data!.distanceGoal,
          label: 'Distance',
          colors: DashboardColors.distanceGradient,
          size: 100,
          unit: 'km',
        ),
        CircularMetric(
          value: _data!.calories.toDouble(),
          goal: _data!.caloriesGoal.toDouble(),
          label: 'Calories',
          colors: DashboardColors.caloriesGradient,
          size: 100,
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    if (_data == null) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        StatCard(
          icon: Icons.directions_run,
          iconColor: DashboardColors.activeCaloriesColor,
          value: _data!.activeCalories.toString(),
          label: 'Active Calories',
        ),
        StatCard(
          icon: Icons.event,
          iconColor: DashboardColors.activitiesColor,
          value: _data!.activitiesCount.toString(),
          label: 'Activities',
        ),
        StatCard(
          icon: Icons.local_fire_department,
          iconColor: DashboardColors.remainingColor,
          value: _data!.caloriesRemaining.toString(),
          label: 'Remaining',
        ),
        StatCard(
          icon: Icons.favorite,
          iconColor: const Color(0xFFFF6B9D),
          value: _data!.avgHeartRate > 0
              ? _data!.avgHeartRate.toStringAsFixed(0)
              : '--',
          label: 'Avg HR',
          subtitle: 'bpm',
        ),
      ],
    );
  }

  Widget _buildActivityChart() {
    if (_data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Last 30 Days',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_data!.monthlyActivities.where((v) => v > 0).length} active days',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ActivityBarChart(
            data: _data!.monthlyActivities,
            height: 100,
            gradientColors: DashboardColors.activityChartGradient,
            showLabels: true,
            labels: const ['30 days ago', 'Today'],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_data == null || _data!.weeklySteps.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week - Steps',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          WeeklyActivityChart(
            data: _data!.weeklySteps,
            gradientColors: DashboardColors.stepsGradient,
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.calendar_today,
            label: 'Calendar',
            color: const Color(0xFF667EEA),
            onTap: () => widget.onNavigate?.call(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.watch,
            label: 'GPS Connect',
            color: const Color(0xFFF79D00),
            onTap: () => widget.onNavigate?.call(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.assessment,
            label: 'AISRI',
            color: const Color(0xFF64F38C),
            onTap: () => widget.onNavigate?.call(2),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
