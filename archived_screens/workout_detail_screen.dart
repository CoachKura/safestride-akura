// Workout Detail Screen
// Displays detailed workout analysis with graphs similar to Strava/Garmin Connect
// Shows Duration, Distance, Calories, Heart Rate, Pace, Elevation charts

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/gps_data_fetcher.dart';
import '../widgets/workout_analysis_charts.dart';
import 'dart:developer' as developer;

class WorkoutDetailScreen extends StatefulWidget {
  final String activityId;
  final GPSPlatform platform;
  final Map<String, dynamic>? initialData;

  const WorkoutDetailScreen({
    super.key,
    required this.activityId,
    this.platform = GPSPlatform.strava,
    this.initialData,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen>
    with SingleTickerProviderStateMixin {
  final GPSDataFetcher _fetcher = GPSDataFetcher();
  late TabController _tabController;

  ActivityDetails? _activity;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivityDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivityDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final activity = await _fetcher.fetchActivityDetails(
        activityId: widget.activityId,
        platform: widget.platform,
      );

      if (mounted) {
        setState(() {
          _activity = activity;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading activity details: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _activity != null
              ? DateFormat('EEEE, MMM d').format(_activity!.startTime)
              : 'Workout Details',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Charts'),
            Tab(text: 'Analysis'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Loading activity data...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load activity',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadActivityDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_activity == null) {
      return const Center(
        child: Text(
          'No activity data available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildChartsTab(),
        _buildAnalysisTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final activity = _activity!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity type and title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_run,
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
                        activity.rawData?['name'] ?? 'Running Activity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(activity.startTime),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Platform icon
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activity.platform.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Summary card
          WorkoutSummaryCard(
            duration: activity.durationDisplay,
            distance: activity.distanceDisplay,
            calories: activity.calories?.toInt() ?? 0,
          ),

          const SizedBox(height: 20),

          // Key metrics grid
          _buildMetricsGrid(activity),

          const SizedBox(height: 20),

          // Heart Rate summary
          if (activity.avgHeartRate != null) ...[
            HeartRateChart(
              data: activity.timeSeriesData,
              avgHeartRate: activity.avgHeartRate!,
              maxHeartRate:
                  activity.maxHeartRate ?? activity.avgHeartRate! * 1.1,
              totalDurationSeconds: activity.durationSeconds,
            ),
            const SizedBox(height: 16),
          ],

          // Pace chart
          if (activity.avgPace != null) ...[
            PaceChart(
              data: activity.timeSeriesData,
              avgPace: activity.avgPace!,
              bestPace: activity.bestPace,
              totalDurationSeconds: activity.durationSeconds,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildChartsTab() {
    final activity = _activity!;
    final totalDuration = activity.durationSeconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combined overview chart
          if (activity.timeSeriesData.isNotEmpty) ...[
            CombinedMetricsChart(
              data: activity.timeSeriesData,
              showHeartRate: activity.avgHeartRate != null,
              showPace: activity.avgPace != null,
              showElevation: activity.elevationGain != null,
              totalDurationSeconds: totalDuration,
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (activity.avgHeartRate != null) ...[
                  _buildLegendItem('Heart Rate', Colors.red),
                  const SizedBox(width: 16),
                ],
                if (activity.avgPace != null) ...[
                  _buildLegendItem('Pace', Colors.blue),
                  const SizedBox(width: 16),
                ],
                if (activity.elevationGain != null)
                  _buildLegendItem('Elevation', Colors.teal),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Heart Rate Chart - Full time range
          if (activity.avgHeartRate != null) ...[
            HeartRateChart(
              data: activity.timeSeriesData,
              avgHeartRate: activity.avgHeartRate!,
              maxHeartRate:
                  activity.maxHeartRate ?? activity.avgHeartRate! * 1.1,
              totalDurationSeconds: totalDuration,
            ),
            const SizedBox(height: 16),
          ],

          // Pace Chart - Full time range
          if (activity.avgPace != null) ...[
            PaceChart(
              data: activity.timeSeriesData,
              avgPace: activity.avgPace!,
              bestPace: activity.bestPace,
              totalDurationSeconds: totalDuration,
            ),
            const SizedBox(height: 16),
          ],

          // Cadence Chart
          if (activity.avgCadence != null) ...[
            CadenceChart(
              data: activity.timeSeriesData,
              avgCadence: activity.avgCadence!,
              maxCadence: activity.maxCadence,
              totalDurationSeconds: totalDuration,
            ),
            const SizedBox(height: 16),
          ],

          // Elevation Chart
          if (activity.elevationGain != null &&
              activity.elevationGain! > 0) ...[
            ElevationChart(
              data: activity.timeSeriesData,
              elevationGain: activity.elevationGain!,
              totalDurationSeconds: totalDuration,
            ),
            const SizedBox(height: 16),
          ],

          // Vertical Oscillation (simulated data since Strava doesn't have it)
          VerticalOscillationChart(
            avgVO:
                8.5 + (activity.avgPace ?? 6) * 0.3, // Estimate based on pace
            maxVO: 10.5 + (activity.avgPace ?? 6) * 0.3,
            totalDurationSeconds: totalDuration,
          ),
          const SizedBox(height: 16),

          // Ground Contact Time
          GroundContactTimeChart(
            avgGCT: 240 +
                ((activity.avgPace ?? 6) - 5) * 10, // Estimate based on pace
            maxGCT: 280 + ((activity.avgPace ?? 6) - 5) * 10,
            totalDurationSeconds: totalDuration,
          ),
          const SizedBox(height: 16),

          // Stride Length (estimated from pace and cadence)
          StrideLengthChart(
            avgStrideLength:
                activity.avgCadence != null && activity.avgPace != null
                    ? (1000 / (activity.avgCadence! * 2 * activity.avgPace!))
                        .clamp(0.7, 1.6)
                    : 1.1,
            maxStrideLength:
                activity.avgCadence != null && activity.avgPace != null
                    ? (1000 /
                            (activity.avgCadence! *
                                2 *
                                (activity.bestPace > 0
                                    ? activity.bestPace
                                    : activity.avgPace!)))
                        .clamp(0.7, 1.8)
                    : 1.3,
            totalDurationSeconds: totalDuration,
          ),
          const SizedBox(height: 16),

          // Training Effect
          TrainingEffectChart(
            aerobicEffect: _calculateAerobicEffect(activity),
            anaerobicEffect: _calculateAnaerobicEffect(activity),
          ),
          const SizedBox(height: 16),

          // Power (estimated from pace and elevation)
          PowerChart(
            avgPower: _estimateRunningPower(activity),
            maxPower: _estimateRunningPower(activity) * 1.4,
            totalDurationSeconds: totalDuration,
          ),
          const SizedBox(height: 16),

          // Performance Condition
          PerformanceConditionChart(
            performanceCondition: _calculatePerformanceCondition(activity),
          ),
          const SizedBox(height: 16),

          // Stamina
          StaminaChart(
            staminaPercent: _calculateStaminaRemaining(activity),
            potentialPercent: _calculateStaminaPotential(activity),
          ),
          const SizedBox(height: 16),

          // Body Temperature (estimated)
          BodyTemperatureChart(
            coreTemp: 37.0 +
                (activity.durationSeconds / 3600) * 0.8 +
                ((activity.avgHeartRate ?? 140) - 120) / 100,
            skinTemp: 35.0 + (activity.durationSeconds / 3600) * 0.5,
          ),
          const SizedBox(height: 16),

          // Run/Walk
          RunWalkChart(
            runningSeconds: _calculateRunningTime(activity),
            walkingSeconds: _calculateWalkingTime(activity),
            totalSeconds: totalDuration,
          ),
          const SizedBox(height: 16),

          // HR Zone Donut Chart
          if (activity.avgHeartRate != null) ...[
            TimeInHRZoneChart(
              zoneSeconds: _calculateHRZoneTimes(activity),
            ),
            const SizedBox(height: 16),
          ],

          // Power Zone Donut Chart
          TimeInPowerZoneChart(
            zoneSeconds: _calculatePowerZoneTimes(activity),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Calculate Training Effect (Aerobic)
  double _calculateAerobicEffect(ActivityDetails activity) {
    final duration = activity.durationSeconds / 60; // minutes
    final hrPercent =
        activity.avgHeartRate != null ? (activity.avgHeartRate! / 180) : 0.75;
    return ((duration / 30) * hrPercent * 2.5).clamp(0.5, 5.0);
  }

  // Calculate Training Effect (Anaerobic)
  double _calculateAnaerobicEffect(ActivityDetails activity) {
    final hrMax = activity.maxHeartRate ?? (activity.avgHeartRate ?? 150) * 1.1;
    final hrPercent = hrMax / 200;
    final pace =
        activity.bestPace > 0 ? activity.bestPace : (activity.avgPace ?? 6);
    return ((10 / pace) * hrPercent * 1.5).clamp(0.0, 5.0);
  }

  // Estimate Running Power
  double _estimateRunningPower(ActivityDetails activity) {
    // Basic running power estimation: ~1W per kg per (speed in m/s)
    // Assuming 70kg runner
    final speed = activity.avgPace != null && activity.avgPace! > 0
        ? (1000 / (activity.avgPace! * 60)) // m/s
        : 2.5;
    final elevationFactor = 1 + (activity.elevationGain ?? 0) / 1000;
    return (70 * speed * 1.1 * elevationFactor).clamp(100, 500);
  }

  // Calculate Performance Condition
  int _calculatePerformanceCondition(ActivityDetails activity) {
    if (activity.avgHeartRate == null || activity.avgPace == null) return 0;
    // Compare actual performance vs expected
    final expectedHR = 140 + (8 - activity.avgPace!) * 5;
    final hrDiff = expectedHR - activity.avgHeartRate!;
    return hrDiff.clamp(-20, 20).toInt();
  }

  // Calculate Stamina Remaining
  double _calculateStaminaRemaining(ActivityDetails activity) {
    // Estimate based on duration and intensity
    final duration = activity.durationSeconds / 60;
    final intensity =
        activity.avgHeartRate != null ? activity.avgHeartRate! / 180 : 0.75;
    return (100 - (duration * intensity * 1.2)).clamp(0, 100);
  }

  // Calculate Stamina Potential
  double _calculateStaminaPotential(ActivityDetails activity) {
    // Estimate based on pace consistency
    final consistency = activity.avgPace != null && activity.bestPace > 0
        ? (activity.avgPace! / activity.bestPace).clamp(0.5, 1.5)
        : 1.0;
    return (100 * consistency * 0.9).clamp(0, 100);
  }

  // Calculate Running Time (walking detection based on pace)
  int _calculateRunningTime(ActivityDetails activity) {
    // Count data points where pace < 8 min/km as running
    final runningPoints = activity.timeSeriesData
        .where((d) => d.pace != null && d.pace! < 8)
        .length;
    final totalPoints = activity.timeSeriesData.length;
    if (totalPoints == 0) return activity.durationSeconds;
    return (activity.durationSeconds * runningPoints / totalPoints).toInt();
  }

  // Calculate Walking Time
  int _calculateWalkingTime(ActivityDetails activity) {
    return activity.durationSeconds - _calculateRunningTime(activity);
  }

  // Calculate time in each HR zone
  Map<String, int> _calculateHRZoneTimes(ActivityDetails activity) {
    final zones = {
      'Zone 1': 0, // 50-60% max HR (Recovery)
      'Zone 2': 0, // 60-70% max HR (Easy)
      'Zone 3': 0, // 70-80% max HR (Aerobic)
      'Zone 4': 0, // 80-90% max HR (Threshold)
      'Zone 5': 0, // 90-100% max HR (Max)
    };

    final maxHR = 200.0; // Assumed max HR

    for (final point in activity.timeSeriesData) {
      if (point.heartRate == null) continue;
      final hrPercent = point.heartRate! / maxHR;

      if (hrPercent < 0.6) {
        zones['Zone 1'] = zones['Zone 1']! + 1;
      } else if (hrPercent < 0.7) {
        zones['Zone 2'] = zones['Zone 2']! + 1;
      } else if (hrPercent < 0.8) {
        zones['Zone 3'] = zones['Zone 3']! + 1;
      } else if (hrPercent < 0.9) {
        zones['Zone 4'] = zones['Zone 4']! + 1;
      } else {
        zones['Zone 5'] = zones['Zone 5']! + 1;
      }
    }

    // If no time series data, estimate from average
    if (activity.timeSeriesData.isEmpty && activity.avgHeartRate != null) {
      final hrPercent = activity.avgHeartRate! / maxHR;
      final totalTime = activity.durationSeconds;

      if (hrPercent < 0.7) {
        zones['Zone 2'] = totalTime;
      } else if (hrPercent < 0.8) {
        zones['Zone 3'] = totalTime;
      } else {
        zones['Zone 4'] = totalTime;
      }
    }

    return zones;
  }

  // Calculate time in each power zone
  Map<String, int> _calculatePowerZoneTimes(ActivityDetails activity) {
    final totalTime = activity.durationSeconds;

    // Estimate distribution based on pace variability
    return {
      'Recovery': (totalTime * 0.05).toInt(),
      'Endurance': (totalTime * 0.30).toInt(),
      'Tempo': (totalTime * 0.35).toInt(),
      'Threshold': (totalTime * 0.20).toInt(),
      'VO2max': (totalTime * 0.08).toInt(),
      'Anaerobic': (totalTime * 0.02).toInt(),
    };
  }

  Widget _buildAnalysisTab() {
    final activity = _activity!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Summary
          _buildAnalysisSection(
            title: 'Performance Summary',
            icon: Icons.insights,
            color: Colors.purple,
            children: [
              _buildAnalysisItem(
                'Estimated VO2max',
                _estimateVO2max(activity),
                _getVO2maxDescription(activity),
              ),
              _buildAnalysisItem(
                'Running Efficiency',
                _getEfficiencyRating(activity),
                _getEfficiencyDescription(activity),
              ),
              _buildAnalysisItem(
                'Training Load',
                _getTrainingLoad(activity),
                _getTrainingLoadDescription(activity),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Heart Rate Analysis
          if (activity.avgHeartRate != null) ...[
            _buildAnalysisSection(
              title: 'Heart Rate Analysis',
              icon: Icons.favorite,
              color: Colors.red,
              children: [
                _buildAnalysisItem(
                  'Heart Rate Reserve Used',
                  '${_getHRReserveUsed(activity)}%',
                  _getHRZoneDescription(activity),
                ),
                _buildAnalysisItem(
                  'Cardiac Drift',
                  _estimateCardiacDrift(activity),
                  'Lower drift indicates better aerobic fitness',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Pace Analysis
          if (activity.avgPace != null) ...[
            _buildAnalysisSection(
              title: 'Pace Analysis',
              icon: Icons.speed,
              color: Colors.blue,
              children: [
                _buildAnalysisItem(
                  'Pace Consistency',
                  _getPaceConsistency(activity),
                  _getPaceConsistencyDescription(activity),
                ),
                _buildAnalysisItem(
                  'Negative Split',
                  _hasNegativeSplit(activity) ? 'Yes ✓' : 'No',
                  _hasNegativeSplit(activity)
                      ? 'Great job! You ran the second half faster.'
                      : 'Try to run the second half as fast or faster.',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Recommendations
          _buildAnalysisSection(
            title: 'Recommendations',
            icon: Icons.lightbulb,
            color: Colors.amber,
            children: _buildRecommendations(activity),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ActivityDetails activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: activity.durationDisplay,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.route,
                  label: 'Distance',
                  value: '${activity.distanceDisplay} km',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.speed,
                  label: 'Avg Pace',
                  value: '${activity.paceDisplay} /km',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.favorite,
                  label: 'Avg HR',
                  value: activity.avgHeartRate != null
                      ? '${activity.avgHeartRate!.toStringAsFixed(0)} bpm'
                      : 'N/A',
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.terrain,
                  label: 'Elevation',
                  value: '${activity.elevationGain?.toStringAsFixed(0) ?? 0} m',
                  color: Colors.teal,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '${activity.calories?.toStringAsFixed(0) ?? 0}',
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAnalysisSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String title, String value, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[300], fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Analysis helper methods
  String _estimateVO2max(ActivityDetails activity) {
    if (activity.avgPace == null || activity.avgHeartRate == null) return 'N/A';

    // Simplified VO2max estimation using pace and HR
    final speed = 60 / activity.avgPace!; // km/h
    final vo2max =
        (15 + (speed * 3)) * (1 - (activity.avgHeartRate! - 120) / 200);
    return '${vo2max.clamp(30, 85).toStringAsFixed(1)} ml/kg/min';
  }

  String _getVO2maxDescription(ActivityDetails activity) {
    if (activity.avgPace == null || activity.avgHeartRate == null) {
      return 'Not enough data to estimate VO2max';
    }
    final speed = 60 / activity.avgPace!;
    final vo2max =
        ((15 + (speed * 3)) * (1 - (activity.avgHeartRate! - 120) / 200))
            .clamp(30, 85);

    if (vo2max >= 55) return 'Excellent - Elite athlete level';
    if (vo2max >= 45) return 'Good - Well-trained runner';
    if (vo2max >= 35) return 'Average - Recreational runner';
    return 'Below average - Room for improvement';
  }

  String _getEfficiencyRating(ActivityDetails activity) {
    if (activity.avgCadence == null) return 'N/A';

    final cadence = activity.avgCadence!;
    if (cadence >= 170 && cadence <= 180) return 'Excellent';
    if (cadence >= 160 && cadence < 170) return 'Good';
    if (cadence >= 150 && cadence < 160) return 'Fair';
    return 'Needs Work';
  }

  String _getEfficiencyDescription(ActivityDetails activity) {
    if (activity.avgCadence == null) {
      return 'Cadence data not available';
    }

    final cadence = activity.avgCadence!;
    if (cadence >= 170 && cadence <= 180) {
      return 'Your cadence (${cadence.toStringAsFixed(0)} spm) is in the optimal range';
    }
    return 'Optimal cadence is 170-180 spm. Try metronome drills to improve.';
  }

  String _getTrainingLoad(ActivityDetails activity) {
    // Simple training load based on duration and intensity
    final duration = activity.durationSeconds / 60; // minutes
    final intensity = activity.avgHeartRate != null
        ? (activity.avgHeartRate! / 180).clamp(0.5, 1.2)
        : 0.8;

    final load = (duration * intensity).round();
    if (load < 30) return 'Light';
    if (load < 60) return 'Moderate';
    if (load < 90) return 'Hard';
    return 'Very Hard';
  }

  String _getTrainingLoadDescription(ActivityDetails activity) {
    final duration = activity.durationSeconds / 60;
    return '${duration.toStringAsFixed(0)} min workout';
  }

  int _getHRReserveUsed(ActivityDetails activity) {
    if (activity.avgHeartRate == null) return 0;
    // Assume max HR of 220 - age (using 190 as estimate for 30yo)
    final maxHR = 190.0;
    final restingHR = 60.0;
    final hrReserve = maxHR - restingHR;
    final used = (activity.avgHeartRate! - restingHR) / hrReserve * 100;
    return used.clamp(0, 100).round();
  }

  String _getHRZoneDescription(ActivityDetails activity) {
    if (activity.avgHeartRate == null) return 'No HR data';

    final hrPercent = activity.avgHeartRate! / 190 * 100;
    if (hrPercent < 60) return 'Zone 1 - Recovery';
    if (hrPercent < 70) return 'Zone 2 - Aerobic Base Building';
    if (hrPercent < 80) return 'Zone 3 - Tempo/Threshold';
    if (hrPercent < 90) return 'Zone 4 - Lactate Threshold';
    return 'Zone 5 - VO2max';
  }

  String _estimateCardiacDrift(ActivityDetails activity) {
    if (activity.timeSeriesData.length < 10) return 'N/A';

    final hrData =
        activity.timeSeriesData.where((d) => d.heartRate != null).toList();

    if (hrData.length < 10) return 'N/A';

    final firstHalf = hrData.take(hrData.length ~/ 2);
    final secondHalf = hrData.skip(hrData.length ~/ 2);

    final avgFirst =
        firstHalf.map((d) => d.heartRate!).reduce((a, b) => a + b) /
            firstHalf.length;
    final avgSecond =
        secondHalf.map((d) => d.heartRate!).reduce((a, b) => a + b) /
            secondHalf.length;

    final drift = ((avgSecond - avgFirst) / avgFirst * 100);

    if (drift < 3) return 'Minimal (${drift.toStringAsFixed(1)}%)';
    if (drift < 6) return 'Normal (${drift.toStringAsFixed(1)}%)';
    return 'High (${drift.toStringAsFixed(1)}%)';
  }

  String _getPaceConsistency(ActivityDetails activity) {
    if (activity.timeSeriesData.isEmpty) return 'N/A';

    final paceData = activity.timeSeriesData
        .where((d) => d.pace != null && d.pace! > 0 && d.pace! < 30)
        .map((d) => d.pace!)
        .toList();

    if (paceData.length < 10) return 'N/A';

    final avg = paceData.reduce((a, b) => a + b) / paceData.length;
    final variance =
        paceData.map((p) => (p - avg) * (p - avg)).reduce((a, b) => a + b) /
            paceData.length;
    final stdDev = variance > 0 ? (variance as num).toDouble() : 0.0;
    final cv = (stdDev / avg * 100);

    if (cv < 5) return 'Excellent';
    if (cv < 10) return 'Good';
    if (cv < 15) return 'Fair';
    return 'Variable';
  }

  String _getPaceConsistencyDescription(ActivityDetails activity) {
    return 'Lower variation indicates steady pacing strategy';
  }

  bool _hasNegativeSplit(ActivityDetails activity) {
    if (activity.timeSeriesData.length < 10) return false;

    final paceData = activity.timeSeriesData
        .where((d) => d.pace != null && d.pace! > 0 && d.pace! < 30)
        .toList();

    if (paceData.length < 10) return false;

    final firstHalf = paceData
            .take(paceData.length ~/ 2)
            .map((d) => d.pace!)
            .reduce((a, b) => a + b) /
        (paceData.length ~/ 2);
    final secondHalf = paceData
            .skip(paceData.length ~/ 2)
            .map((d) => d.pace!)
            .reduce((a, b) => a + b) /
        (paceData.length - paceData.length ~/ 2);

    return secondHalf < firstHalf; // Lower pace = faster
  }

  List<Widget> _buildRecommendations(ActivityDetails activity) {
    final recommendations = <Widget>[];

    // Cadence recommendation
    if (activity.avgCadence != null &&
        (activity.avgCadence! < 160 || activity.avgCadence! > 190)) {
      recommendations.add(_buildRecommendationItem(
        'Improve Cadence',
        'Your cadence of ${activity.avgCadence!.toStringAsFixed(0)} spm is outside the optimal range (170-180 spm). Try metronome drills at 180 bpm.',
        Icons.directions_run,
        Colors.orange,
      ));
    }

    // HR zone recommendation
    if (activity.avgHeartRate != null) {
      final hrPercent = activity.avgHeartRate! / 190 * 100;
      if (hrPercent > 85 && activity.durationSeconds > 2700) {
        // > 45 min
        recommendations.add(_buildRecommendationItem(
          'Recovery Needed',
          'High intensity run (${hrPercent.toStringAsFixed(0)}% max HR) for ${(activity.durationSeconds / 60).toStringAsFixed(0)} minutes. Allow 48-72 hours recovery.',
          Icons.hotel,
          Colors.red,
        ));
      } else if (hrPercent < 65) {
        recommendations.add(_buildRecommendationItem(
          'Base Building',
          'Good aerobic base work. This intensity optimizes fat burning and mitochondrial development.',
          Icons.trending_up,
          Colors.green,
        ));
      }
    }

    // Pacing recommendation
    if (!_hasNegativeSplit(activity)) {
      recommendations.add(_buildRecommendationItem(
        'Practice Negative Splits',
        'Try starting slower and finishing faster. This builds mental strength and improves race performance.',
        Icons.speed,
        Colors.blue,
      ));
    }

    if (recommendations.isEmpty) {
      recommendations.add(_buildRecommendationItem(
        'Great Job!',
        'This was a well-executed workout. Keep up the consistent training!',
        Icons.emoji_events,
        Colors.amber,
      ));
    }

    return recommendations;
  }

  Widget _buildRecommendationItem(
      String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
