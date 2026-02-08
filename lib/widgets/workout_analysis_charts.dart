// Workout Analysis Charts
// Displays detailed workout metrics with interactive graphs
// Similar to Strava/Garmin Connect visualizations

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../services/gps_data_fetcher.dart';

/// Workout Summary Card - Shows Duration, Distance, Calories in circular progress
class WorkoutSummaryCard extends StatelessWidget {
  final String duration;
  final String distance;
  final int calories;

  const WorkoutSummaryCard({
    super.key,
    required this.duration,
    required this.distance,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryMetric(
            value: duration,
            label: 'Duration',
            icon: Icons.timer_outlined,
            color: Colors.blue,
          ),
          _SummaryMetric(
            value: distance,
            label: 'Distance (km)',
            icon: Icons.route,
            color: Colors.orange,
          ),
          _SummaryMetric(
            value: calories.toString(),
            label: 'Calories',
            icon: Icons.local_fire_department,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

// ==================== HEART RATE CHART ====================

class HeartRateChart extends StatelessWidget {
  final List<DataPoint> data;
  final double avgHeartRate;
  final double maxHeartRate;
  final int totalDurationSeconds;

  const HeartRateChart({
    super.key,
    required this.data,
    required this.avgHeartRate,
    required this.maxHeartRate,
    this.totalDurationSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hrData = data.where((d) => d.heartRate != null).toList();
    if (hrData.isEmpty) {
      return _buildEmptyState('No heart rate data available');
    }

    final duration = totalDurationSeconds > 0
        ? totalDurationSeconds
        : (hrData.isNotEmpty ? hrData.last.timeSeconds : 0);

    return _ChartContainer(
      title: 'Heart Rate',
      icon: Icons.favorite,
      iconColor: Colors.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricDisplay(
                value: avgHeartRate.toStringAsFixed(0),
                unit: 'bpm',
                label: 'Average',
                color: Colors.red,
                isLarge: true,
              ),
              _MetricDisplay(
                value: maxHeartRate.toStringAsFixed(0),
                unit: 'bpm',
                label: 'Maximum',
                color: Colors.red[300]!,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart - Full time axis showing every second
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  verticalInterval: duration > 0 ? duration / 4 : 60,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[800]!,
                    strokeWidth: 0.5,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey[800]!,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: _buildFullTimeTitles(duration),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: duration.toDouble(),
                minY: 60,
                maxY: 200,
                lineBarsData: [
                  LineChartBarData(
                    spots: hrData
                        .map((d) =>
                            FlSpot(d.timeSeconds.toDouble(), d.heartRate!))
                        .toList(),
                    isCurved: false,
                    color: Colors.red,
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  // Average line (dashed)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, avgHeartRate),
                      FlSpot(duration.toDouble(), avgHeartRate),
                    ],
                    isCurved: false,
                    color: Colors.white.withValues(alpha: 0.5),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [8, 4],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final time = _formatTimeMinSec(spot.x.toInt());
                        return LineTooltipItem(
                          '${spot.y.toInt()} bpm\n$time',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildFullTimeTitles(int duration) {
    final interval = duration > 0 ? duration / 4 : 60.0;
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35,
          interval: 20,
          getTitlesWidget: (value, meta) {
            if (value == 60 ||
                value == 100 ||
                value == 140 ||
                value == 160 ||
                value == 180) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final minutes = value.toInt() ~/ 60;
            return Text(
              '${minutes}m',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  String _formatTimeMinSec(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}

// ==================== PACE CHART ====================

class PaceChart extends StatelessWidget {
  final List<DataPoint> data;
  final double avgPace;
  final double bestPace;
  final int totalDurationSeconds;

  const PaceChart({
    super.key,
    required this.data,
    required this.avgPace,
    required this.bestPace,
    this.totalDurationSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    final paceData = data
        .where((d) => d.pace != null && d.pace! > 0 && d.pace! < 30)
        .toList();
    if (paceData.isEmpty) {
      return _buildEmptyState('No pace data available');
    }

    final duration = totalDurationSeconds > 0
        ? totalDurationSeconds
        : (paceData.isNotEmpty ? paceData.last.timeSeconds : 0);

    return _ChartContainer(
      title: 'Pace',
      icon: Icons.speed,
      iconColor: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricDisplay(
                value: _formatPace(avgPace),
                unit: '/km',
                label: 'Average',
                color: Colors.blue,
                isLarge: true,
              ),
              _MetricDisplay(
                value: _formatPace(bestPace),
                unit: '/km',
                label: 'Best',
                color: Colors.blue[300]!,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart - Full time axis showing every second
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 2,
                  verticalInterval: duration > 0 ? duration / 4 : 60,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[800]!,
                    strokeWidth: 0.5,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey[800]!,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: _buildFullTimeTitles(duration),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: duration.toDouble(),
                minY: 4,
                maxY: 20,
                lineBarsData: [
                  LineChartBarData(
                    spots: paceData
                        .map((d) => FlSpot(
                            d.timeSeconds.toDouble(), d.pace!.clamp(4, 20)))
                        .toList(),
                    isCurved: false,
                    color: Colors.blue,
                    barWidth: 1.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  // Average line (dashed)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, avgPace),
                      FlSpot(duration.toDouble(), avgPace),
                    ],
                    isCurved: false,
                    color: Colors.white.withValues(alpha: 0.5),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [8, 4],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildFullTimeTitles(int duration) {
    final interval = duration > 0 ? duration / 4 : 60.0;
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45,
          interval: 2,
          getTitlesWidget: (value, meta) {
            if (value >= 4 && value <= 20 && value % 2 == 0) {
              return Text(
                _formatPace(value),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final minutes = value.toInt() ~/ 60;
            return Text(
              '${minutes}m',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  String _formatPace(double pace) {
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// ==================== CADENCE CHART ====================

class CadenceChart extends StatelessWidget {
  final List<DataPoint> data;
  final double avgCadence;
  final double? maxCadence;
  final int totalDurationSeconds;

  const CadenceChart({
    super.key,
    required this.data,
    required this.avgCadence,
    this.maxCadence,
    this.totalDurationSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cadenceData =
        data.where((d) => d.cadence != null && d.cadence! > 0).toList();
    if (cadenceData.isEmpty) {
      return _buildEmptyState('No cadence data available');
    }

    final duration = totalDurationSeconds > 0
        ? totalDurationSeconds
        : (cadenceData.isNotEmpty ? cadenceData.last.timeSeconds : 0);

    return _ChartContainer(
      title: 'Cadence',
      icon: Icons.directions_run,
      iconColor: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricDisplay(
                value: avgCadence.toStringAsFixed(0),
                unit: 'spm',
                label: 'Average',
                color: Colors.orange,
                isLarge: true,
              ),
              if (maxCadence != null)
                _MetricDisplay(
                  value: maxCadence!.toStringAsFixed(0),
                  unit: 'spm',
                  label: 'Maximum',
                  color: Colors.orange[300]!,
                ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: duration > 0 ? duration / 4 : 60,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[800]!,
                    strokeWidth: 0.5,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey[800]!,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: _buildFullTimeTitles(duration),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: duration.toDouble(),
                minY: 100,
                maxY: 200,
                lineBarsData: [
                  LineChartBarData(
                    spots: cadenceData
                        .map((d) => FlSpot(d.timeSeconds.toDouble(),
                            (d.cadence! * 2).clamp(100, 200)))
                        .toList(),
                    isCurved: false,
                    color: Colors.orange,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  // Optimal zone indicator (170-180)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 175),
                      FlSpot(duration.toDouble(), 175),
                    ],
                    isCurved: false,
                    color: Colors.green.withValues(alpha: 0.5),
                    barWidth: 1,
                    dotData: const FlDotData(show: false),
                    dashArray: [8, 4],
                  ),
                ],
              ),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                    width: 20,
                    height: 2,
                    color: Colors.green.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text('Optimal: 170-180 spm',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildFullTimeTitles(int duration) {
    final interval = duration > 0 ? duration / 4 : 60.0;
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 35,
          interval: 20,
          getTitlesWidget: (value, meta) {
            if (value >= 100 && value <= 200 && value % 20 == 0) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final minutes = value.toInt() ~/ 60;
            return Text('${minutes}m',
                style: TextStyle(color: Colors.grey[500], fontSize: 10));
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}

// ==================== ELEVATION CHART ====================

class ElevationChart extends StatelessWidget {
  final List<DataPoint> data;
  final double elevationGain;
  final int totalDurationSeconds;

  const ElevationChart({
    super.key,
    required this.data,
    required this.elevationGain,
    this.totalDurationSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    final elevData = data.where((d) => d.elevation != null).toList();
    if (elevData.isEmpty) {
      return _buildEmptyState('No elevation data available');
    }

    final duration = totalDurationSeconds > 0
        ? totalDurationSeconds
        : (elevData.isNotEmpty ? elevData.last.timeSeconds : 0);
    final minElev = elevData.map((d) => d.elevation!).reduce(math.min);
    final maxElev = elevData.map((d) => d.elevation!).reduce(math.max);

    return _ChartContainer(
      title: 'Elevation',
      icon: Icons.terrain,
      iconColor: Colors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricDisplay(
                value: elevationGain.toStringAsFixed(0),
                unit: 'm',
                label: 'Gain',
                color: Colors.teal,
                isLarge: true,
              ),
              Row(
                children: [
                  _MetricDisplay(
                      value: minElev.toStringAsFixed(0),
                      unit: 'm',
                      label: 'Min',
                      color: Colors.teal[300]!),
                  const SizedBox(width: 16),
                  _MetricDisplay(
                      value: maxElev.toStringAsFixed(0),
                      unit: 'm',
                      label: 'Max',
                      color: Colors.teal[300]!),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: _buildFullTimeTitles(duration),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: duration.toDouble(),
                minY: minElev - 5,
                maxY: maxElev + 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: elevData
                        .map((d) =>
                            FlSpot(d.timeSeconds.toDouble(), d.elevation!))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: Colors.teal,
                    barWidth: 0,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.withValues(alpha: 0.6),
                          Colors.teal.withValues(alpha: 0.2)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  FlTitlesData _buildFullTimeTitles(int duration) {
    final interval = duration > 0 ? duration / 4 : 60.0;
    return FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final minutes = value.toInt() ~/ 60;
            return Text('${minutes}m',
                style: TextStyle(color: Colors.grey[500], fontSize: 10));
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}

// ==================== VERTICAL OSCILLATION CHART ====================

class VerticalOscillationChart extends StatelessWidget {
  final double avgVO;
  final double? maxVO;
  final int totalDurationSeconds;
  final List<DataPoint>? data;

  const VerticalOscillationChart({
    super.key,
    required this.avgVO,
    this.maxVO,
    this.totalDurationSeconds = 0,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Vertical Oscillation',
      icon: Icons.swap_vert,
      iconColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricDisplay(
                value: avgVO.toStringAsFixed(1),
                unit: 'cm',
                label: 'Average',
                color: Colors.purple,
                isLarge: true,
              ),
              if (maxVO != null)
                _MetricDisplay(
                  value: maxVO!.toStringAsFixed(1),
                  unit: 'cm',
                  label: 'Maximum',
                  color: Colors.purple[300]!,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress indicator showing efficiency
          _buildEfficiencyIndicator(avgVO),

          const SizedBox(height: 8),
          Text(
            avgVO < 8
                ? 'Excellent - Very efficient running form'
                : avgVO < 10
                    ? 'Good - Efficient running'
                    : 'Focus on reducing vertical bounce',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyIndicator(double value) {
    // Optimal range: 6-10cm
    final percentage = ((10 - value.clamp(4, 14)) / 6 * 100).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.yellow, Colors.red],
                  ),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Optimal',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text('High',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ==================== GROUND CONTACT TIME CHART ====================

class GroundContactTimeChart extends StatelessWidget {
  final double avgGCT;
  final double? maxGCT;
  final int totalDurationSeconds;
  final List<DataPoint>? data;

  const GroundContactTimeChart({
    super.key,
    required this.avgGCT,
    this.maxGCT,
    this.totalDurationSeconds = 0,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Ground Contact Time',
      icon: Icons.timer_outlined,
      iconColor: Colors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricDisplay(
                value: avgGCT.toStringAsFixed(0),
                unit: 'ms',
                label: 'Average',
                color: Colors.cyan,
                isLarge: true,
              ),
              if (maxGCT != null)
                _MetricDisplay(
                  value: maxGCT!.toStringAsFixed(0),
                  unit: 'ms',
                  label: 'Maximum',
                  color: Colors.cyan[300]!,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Efficiency bar
          _buildGCTIndicator(avgGCT),

          const SizedBox(height: 8),
          Text(
            avgGCT < 220
                ? 'Excellent - Elite level GCT'
                : avgGCT < 250
                    ? 'Good - Efficient ground contact'
                    : avgGCT < 280
                        ? 'Average - Room for improvement'
                        : 'Focus on quicker foot turnover',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildGCTIndicator(double value) {
    // Optimal: <250ms
    final percentage =
        ((300 - value.clamp(180, 350)) / 170 * 100).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[800],
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Colors.cyan, Colors.cyanAccent],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    '${avgGCT.toStringAsFixed(0)} ms',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fast (<220ms)',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text('Slow (>280ms)',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ==================== STRIDE LENGTH CHART ====================

class StrideLengthChart extends StatelessWidget {
  final double avgStrideLength;
  final double? maxStrideLength;
  final int totalDurationSeconds;
  final List<DataPoint>? data;

  const StrideLengthChart({
    super.key,
    required this.avgStrideLength,
    this.maxStrideLength,
    this.totalDurationSeconds = 0,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Stride Length',
      icon: Icons.straighten,
      iconColor: Colors.amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricDisplay(
                value: avgStrideLength.toStringAsFixed(2),
                unit: 'm',
                label: 'Average',
                color: Colors.amber,
                isLarge: true,
              ),
              if (maxStrideLength != null)
                _MetricDisplay(
                  value: maxStrideLength!.toStringAsFixed(2),
                  unit: 'm',
                  label: 'Maximum',
                  color: Colors.amber[300]!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStrideLengthIndicator(avgStrideLength),
          const SizedBox(height: 8),
          Text(
            avgStrideLength >= 1.0 && avgStrideLength <= 1.3
                ? 'Optimal stride length for distance running'
                : avgStrideLength < 1.0
                    ? 'Consider increasing stride length slightly'
                    : 'May be overstriding - focus on cadence',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStrideLengthIndicator(double value) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[800],
      ),
      child: Stack(
        children: [
          // Optimal zone marker (1.0-1.3m)
          Positioned(
            left: 80,
            right: 80,
            top: 4,
            bottom: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Current value marker
          Positioned(
            left: ((value - 0.7) / 0.9 * 200).clamp(0, 200),
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
              ),
              child: const Center(
                child: Icon(Icons.circle, color: Colors.white, size: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TRAINING EFFECT CHART ====================

class TrainingEffectChart extends StatelessWidget {
  final double aerobicEffect;
  final double anaerobicEffect;

  const TrainingEffectChart({
    super.key,
    required this.aerobicEffect,
    required this.anaerobicEffect,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Training Effect',
      icon: Icons.fitness_center,
      iconColor: Colors.green,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTrainingEffectGauge(
                    'Aerobic', aerobicEffect, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTrainingEffectGauge(
                    'Anaerobic', anaerobicEffect, Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrainingEffectDescription(aerobicEffect, anaerobicEffect),
        ],
      ),
    );
  }

  Widget _buildTrainingEffectGauge(String label, double value, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: value / 5,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getEffectLevel(value),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 12)),
      ],
    );
  }

  String _getEffectLevel(double value) {
    if (value < 1) return 'Minor';
    if (value < 2) return 'Maintaining';
    if (value < 3) return 'Improving';
    if (value < 4) return 'Highly Improving';
    return 'Overreaching';
  }

  Widget _buildTrainingEffectDescription(double aerobic, double anaerobic) {
    String description;
    if (aerobic >= 3 && anaerobic >= 3) {
      description =
          'High-intensity balanced workout - excellent for overall fitness';
    } else if (aerobic >= 3) {
      description = 'Strong aerobic workout - building endurance base';
    } else if (anaerobic >= 3) {
      description = 'High anaerobic load - building speed and power';
    } else {
      description = 'Moderate workout - maintaining fitness level';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        description,
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ==================== POWER CHART ====================

class PowerChart extends StatelessWidget {
  final double avgPower;
  final double? maxPower;
  final int totalDurationSeconds;
  final List<DataPoint>? data;

  const PowerChart({
    super.key,
    required this.avgPower,
    this.maxPower,
    this.totalDurationSeconds = 0,
    this.data,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Power',
      icon: Icons.flash_on,
      iconColor: Colors.yellow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricDisplay(
                value: avgPower.toStringAsFixed(0),
                unit: 'W',
                label: 'Average',
                color: Colors.yellow,
                isLarge: true,
              ),
              if (maxPower != null)
                _MetricDisplay(
                  value: maxPower!.toStringAsFixed(0),
                  unit: 'W',
                  label: 'Maximum',
                  color: Colors.yellow[300]!,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Power zones bar
          _buildPowerZoneBar(avgPower),
        ],
      ),
    );
  }

  Widget _buildPowerZoneBar(double power) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [
                Colors.grey,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.orange,
                Colors.red,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: (power / 500 * 200).clamp(0, 200),
                top: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recovery',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text('Threshold',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text('Max',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ==================== PERFORMANCE CONDITION CHART ====================

class PerformanceConditionChart extends StatelessWidget {
  final int performanceCondition; // -20 to +20

  const PerformanceConditionChart({
    super.key,
    required this.performanceCondition,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Performance Condition',
      icon: Icons.trending_up,
      iconColor: _getConditionColor(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                performanceCondition >= 0
                    ? '+$performanceCondition'
                    : '$performanceCondition',
                style: TextStyle(
                  color: _getConditionColor(),
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getConditionDescription(),
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildConditionScale(),
        ],
      ),
    );
  }

  Color _getConditionColor() {
    if (performanceCondition >= 5) return Colors.green;
    if (performanceCondition >= -5) return Colors.yellow;
    return Colors.red;
  }

  String _getConditionDescription() {
    if (performanceCondition >= 10) return 'Feeling strong today!';
    if (performanceCondition >= 5) return 'Good condition';
    if (performanceCondition >= -5) return 'Normal performance';
    if (performanceCondition >= -10) return 'Below baseline';
    return 'Consider recovery';
  }

  Widget _buildConditionScale() {
    return Column(
      children: [
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.yellow, Colors.green],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: ((performanceCondition + 20) / 40 * 200).clamp(0, 200),
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: _getConditionColor(), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-20',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text('0', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text('+20',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ==================== STAMINA CHART ====================

class StaminaChart extends StatelessWidget {
  final double staminaPercent; // 0-100
  final double potentialPercent; // 0-100

  const StaminaChart({
    super.key,
    required this.staminaPercent,
    required this.potentialPercent,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Stamina',
      icon: Icons.battery_charging_full,
      iconColor: Colors.lightGreen,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStaminaGauge(
                    'Current', staminaPercent, Colors.lightGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStaminaGauge(
                    'Potential', potentialPercent, Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            staminaPercent > 70
                ? 'High energy reserves - you can push harder'
                : staminaPercent > 40
                    ? 'Moderate stamina - pace yourself'
                    : 'Low stamina - consider slowing down',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStaminaGauge(String label, double percent, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Center(
                child: Text(
                  '${percent.toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 12)),
      ],
    );
  }
}

// ==================== BODY TEMPERATURE CHART ====================

class BodyTemperatureChart extends StatelessWidget {
  final double coreTemp;
  final double? skinTemp;

  const BodyTemperatureChart({
    super.key,
    required this.coreTemp,
    this.skinTemp,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Body Temperature',
      icon: Icons.thermostat,
      iconColor: _getTempColor(coreTemp),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTempDisplay('Core', coreTemp),
              if (skinTemp != null) _buildTempDisplay('Skin', skinTemp!),
            ],
          ),
          const SizedBox(height: 16),
          _buildTempScale(coreTemp),
          const SizedBox(height: 8),
          Text(
            coreTemp < 38
                ? 'Normal - Good thermoregulation'
                : coreTemp < 39
                    ? 'Elevated - Consider cooling down'
                    : 'High - Risk of overheating',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTempDisplay(String label, double temp) {
    return Column(
      children: [
        Text(
          '${temp.toStringAsFixed(1)}°C',
          style: TextStyle(
            color: _getTempColor(temp),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Color _getTempColor(double temp) {
    if (temp < 37.5) return Colors.blue;
    if (temp < 38.5) return Colors.yellow;
    if (temp < 39.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTempScale(double temp) {
    return Column(
      children: [
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.orange,
                Colors.red
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: ((temp - 36) / 4 * 200).clamp(0, 200),
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: _getTempColor(temp), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('36°C',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text('38°C',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text('40°C',
                style: TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ==================== RUN/WALK DETECTION CHART ====================

class RunWalkChart extends StatelessWidget {
  final int runningSeconds;
  final int walkingSeconds;
  final int totalSeconds;

  const RunWalkChart({
    super.key,
    required this.runningSeconds,
    required this.walkingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final runPercent =
        totalSeconds > 0 ? (runningSeconds / totalSeconds * 100) : 0;
    final walkPercent =
        totalSeconds > 0 ? (walkingSeconds / totalSeconds * 100) : 0;

    return _ChartContainer(
      title: 'Run/Walk',
      icon: Icons.directions_walk,
      iconColor: Colors.indigo,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActivityBar('Running', runPercent.toDouble(),
                    Colors.green, runningSeconds),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActivityBar('Walking', walkPercent.toDouble(),
                    Colors.orange, walkingSeconds),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Visual timeline
          Container(
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey[800],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: runningSeconds,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.green,
                    ),
                  ),
                ),
                Expanded(
                  flex: walkingSeconds > 0 ? walkingSeconds : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: walkingSeconds > 0
                          ? Colors.orange
                          : Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar(
      String label, double percent, Color color, int seconds) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
        const Spacer(),
        Text(
          '${_formatDuration(seconds)} (${percent.toStringAsFixed(1)}%)',
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ==================== TIME IN HR ZONE (DONUT) ====================

class TimeInHRZoneChart extends StatelessWidget {
  final Map<String, int> zoneSeconds; // Zone 1-5 with time in seconds

  const TimeInHRZoneChart({
    super.key,
    required this.zoneSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final total = zoneSeconds.values.fold(0, (a, b) => a + b);

    return _ChartContainer(
      title: 'Time in Heart Rate Zone',
      icon: Icons.favorite_border,
      iconColor: Colors.red,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _buildHRZoneSections(total),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildZoneLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildHRZoneSections(int total) {
    final colors = [
      Colors.grey, // Zone 1 - Recovery
      Colors.blue, // Zone 2 - Easy
      Colors.green, // Zone 3 - Aerobic
      Colors.orange, // Zone 4 - Threshold
      Colors.red, // Zone 5 - Max
    ];

    final zones = ['Zone 1', 'Zone 2', 'Zone 3', 'Zone 4', 'Zone 5'];

    return zones.asMap().entries.map((entry) {
      final index = entry.key;
      final zone = entry.value;
      final seconds = zoneSeconds[zone] ?? 0;
      final percent = total > 0 ? (seconds / total * 100) : 0;

      return PieChartSectionData(
        color: colors[index],
        value: percent.toDouble(),
        title: percent > 5 ? '${percent.toStringAsFixed(0)}%' : '',
        radius: 40,
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Widget _buildZoneLegend() {
    final colors = [
      Colors.grey,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red
    ];
    final labels = ['Recovery', 'Easy', 'Aerobic', 'Threshold', 'Max'];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(5, (i) {
        final seconds = zoneSeconds['Zone ${i + 1}'] ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: colors[i], borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text('${labels[i]}: ${_formatDuration(seconds)}',
                style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        );
      }),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ==================== TIME IN POWER ZONE (DONUT) ====================

class TimeInPowerZoneChart extends StatelessWidget {
  final Map<String, int> zoneSeconds; // Power zones with time in seconds

  const TimeInPowerZoneChart({
    super.key,
    required this.zoneSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final total = zoneSeconds.values.fold(0, (a, b) => a + b);

    return _ChartContainer(
      title: 'Time in Power Zone',
      icon: Icons.flash_on,
      iconColor: Colors.yellow,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _buildPowerZoneSections(total),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPowerZoneLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPowerZoneSections(int total) {
    final colors = [
      Colors.grey, // Recovery
      Colors.blue, // Endurance
      Colors.green, // Tempo
      Colors.yellow, // Threshold
      Colors.orange, // VO2max
      Colors.red, // Anaerobic
    ];

    final zones = [
      'Recovery',
      'Endurance',
      'Tempo',
      'Threshold',
      'VO2max',
      'Anaerobic'
    ];

    return zones.asMap().entries.map((entry) {
      final index = entry.key;
      final zone = entry.value;
      final seconds = zoneSeconds[zone] ?? 0;
      final percent = total > 0 ? (seconds / total * 100) : 0;

      return PieChartSectionData(
        color: colors[index],
        value: percent.toDouble(),
        title: percent > 5 ? '${percent.toStringAsFixed(0)}%' : '',
        radius: 40,
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Widget _buildPowerZoneLegend() {
    final colors = [
      Colors.grey,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.red
    ];
    final labels = [
      'Recovery',
      'Endurance',
      'Tempo',
      'Threshold',
      'VO2max',
      'Anaerobic'
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(6, (i) {
        final seconds = zoneSeconds[labels[i]] ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: colors[i], borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text('${labels[i]}: ${_formatDuration(seconds)}',
                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ],
        );
      }),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

// ==================== HELPER WIDGETS ====================

class _ChartContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ChartContainer({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, color: iconColor, size: 20),
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
          child,
        ],
      ),
    );
  }
}

class _MetricDisplay extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;
  final bool isLarge;

  const _MetricDisplay({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: isLarge ? 32 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: isLarge ? 14 : 12,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

Widget _buildEmptyState(String message) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(16),
    ),
    height: 150,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, color: Colors.grey[600], size: 40),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    ),
  );
}

// ==================== COMBINED METRICS CHART ====================

class CombinedMetricsChart extends StatelessWidget {
  final List<DataPoint> data;
  final bool showHeartRate;
  final bool showPace;
  final bool showElevation;
  final int totalDurationSeconds;

  const CombinedMetricsChart({
    super.key,
    required this.data,
    this.showHeartRate = true,
    this.showPace = true,
    this.showElevation = true,
    this.totalDurationSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('No data available');
    }

    final duration = totalDurationSeconds > 0
        ? totalDurationSeconds
        : (data.isNotEmpty ? data.last.timeSeconds : 0);

    return _ChartContainer(
      title: 'Activity Overview',
      icon: Icons.analytics,
      iconColor: Colors.purple,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 25,
              verticalInterval: duration > 0 ? duration / 4 : 60,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey[800]!,
                strokeWidth: 0.5,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey[800]!,
                strokeWidth: 0.5,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: duration > 0 ? duration / 4 : 60,
                  getTitlesWidget: (value, meta) {
                    final minutes = value.toInt() ~/ 60;
                    return Text('${minutes}m',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 10));
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: duration.toDouble(),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              if (showHeartRate)
                _buildNormalizedLine(
                    data, (d) => d.heartRate, Colors.red, 60, 200),
              if (showPace) _buildNormalizedPaceLine(data, Colors.blue),
              if (showElevation)
                _buildNormalizedElevationLine(data, Colors.teal),
            ],
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildNormalizedLine(
    List<DataPoint> data,
    double? Function(DataPoint) getValue,
    Color color,
    double minVal,
    double maxVal,
  ) {
    final validData = data.where((d) => getValue(d) != null).toList();
    return LineChartBarData(
      spots: validData.map((d) {
        final normalized =
            ((getValue(d)! - minVal) / (maxVal - minVal) * 100).clamp(0, 100);
        return FlSpot(d.timeSeconds.toDouble(), normalized.toDouble());
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }

  LineChartBarData _buildNormalizedPaceLine(List<DataPoint> data, Color color) {
    final validData = data
        .where((d) => d.pace != null && d.pace! > 0 && d.pace! < 30)
        .toList();
    if (validData.isEmpty) return LineChartBarData(spots: []);

    final minPace = validData.map((d) => d.pace!).reduce(math.min);
    final maxPace = validData.map((d) => d.pace!).reduce(math.max);

    return LineChartBarData(
      spots: validData.map((d) {
        // Invert: lower pace = higher on chart
        final normalized = maxPace > minPace
            ? ((maxPace - d.pace!) / (maxPace - minPace) * 100)
            : 50.0;
        return FlSpot(d.timeSeconds.toDouble(), normalized.clamp(0, 100));
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }

  LineChartBarData _buildNormalizedElevationLine(
      List<DataPoint> data, Color color) {
    final validData = data.where((d) => d.elevation != null).toList();
    if (validData.isEmpty) return LineChartBarData(spots: []);

    final minElev = validData.map((d) => d.elevation!).reduce(math.min);
    final maxElev = validData.map((d) => d.elevation!).reduce(math.max);

    return LineChartBarData(
      spots: validData.map((d) {
        final normalized = maxElev > minElev
            ? ((d.elevation! - minElev) / (maxElev - minElev) * 100)
            : 50.0;
        return FlSpot(d.timeSeconds.toDouble(), normalized.clamp(0, 100));
      }).toList(),
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData:
          BarAreaData(show: true, color: color.withValues(alpha: 0.2)),
    );
  }
}
