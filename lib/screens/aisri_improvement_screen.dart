import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/aisri_improvement_calculator.dart';

/// Screen showing improvement between AISRI assessments
///
/// Displays:
/// - Overall score change with trend arrow
/// - Per-pillar comparison chart
/// - Biggest gains and areas to focus
/// - Running dynamics correlation with insights
/// - Timeline of assessments
class AISRIImprovementScreen extends StatefulWidget {
  final String userId;
  final String? stravaAthleteId;

  const AISRIImprovementScreen({
    super.key,
    required this.userId,
    this.stravaAthleteId,
  });

  @override
  State<AISRIImprovementScreen> createState() => _AISRIImprovementScreenState();
}

class _AISRIImprovementScreenState extends State<AISRIImprovementScreen> {
  Map<String, dynamic>? _improvementData;
  Map<String, dynamic>? _correlationData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImprovementData();
  }

  Future<void> _loadImprovementData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load improvement comparison
      final improvement = await AISRIImprovementCalculator.calculateImprovement(
        userId: widget.userId,
      );

      // Load running dynamics correlation if Strava connected
      Map<String, dynamic>? correlation;
      if (widget.stravaAthleteId != null) {
        correlation =
            await AISRIImprovementCalculator.correlateWithRunningDynamics(
          userId: widget.userId,
          stravaAthleteId: widget.stravaAthleteId!,
        );
      }

      setState(() {
        _improvementData = improvement;
        _correlationData = correlation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load improvement data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 Your AISRI Progress'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadImprovementData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _improvementData == null
                  ? const Center(
                      child: Text(
                        'Complete at least 2 assessments to see improvement.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverallScoreCard(),
                          const SizedBox(height: 20),
                          _buildPillarComparisonChart(),
                          const SizedBox(height: 20),
                          _buildBiggestGainsCard(),
                          const SizedBox(height: 20),
                          _buildAreasToFocusCard(),
                          if (_correlationData != null) ...[
                            const SizedBox(height: 20),
                            _buildRunningCorrelationCard(),
                          ],
                          const SizedBox(height: 20),
                          _buildNextStepsCard(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOverallScoreCard() {
    final overall = _improvementData!['overall'] as Map<String, dynamic>;
    final change = overall['change'] as int;
    final changePercent = overall['change_percent'] as double;
    final previousScore = overall['previous_score'] as int;
    final currentScore = overall['current_score'] as int;

    final isPositive = change >= 0;
    final arrow = isPositive ? '↑' : '↓';
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '🎯 Overall AISRI Score',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Previous',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      previousScore.toString(),
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward, size: 32, color: Colors.grey),
                Column(
                  children: [
                    const Text('Current',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      currentScore.toString(),
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 2),
              ),
              child: Text(
                '$arrow ${change.abs()} points (${changePercent.abs().toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPositive
                  ? '🎉 Great job! You\'re getting better!'
                  : '💪 Keep going! Focus on the areas below.',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarComparisonChart() {
    final pillars = _improvementData!['pillars'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Pillar-by-Pillar Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final pillarNames = [
                            'Adapt',
                            'Injury',
                            'Fatigue',
                            'Recovery',
                            'Intensity',
                            'Consist',
                            'Agility',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < pillarNames.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                pillarNames[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(pillars),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Previous', Colors.blue[300]!),
                const SizedBox(width: 20),
                _buildLegendItem('Current', Colors.green[600]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, dynamic> pillars) {
    final pillarKeys = [
      'pillar_adaptability',
      'pillar_injury_risk',
      'pillar_fatigue',
      'pillar_recovery',
      'pillar_intensity',
      'pillar_consistency',
      'pillar_agility',
    ];

    return List.generate(pillarKeys.length, (index) {
      final key = pillarKeys[index];
      final data = pillars[key] as Map<String, dynamic>;
      final previous = (data['previous'] as int).toDouble();
      final current = (data['current'] as int).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: previous,
            color: Colors.blue[300],
            width: 10,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: current,
            color: Colors.green[600],
            width: 10,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBiggestGainsCard() {
    final biggestGains = _improvementData!['biggest_gains'] as List<dynamic>;

    return Card(
      elevation: 4,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text(
                  '💪 Biggest Gains',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...biggestGains.map((gain) {
              final pillar = gain['pillar'] as String;
              final change = gain['change'] as int;
              final changePercent = gain['change_percent'] as double;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$pillar: +$change points (+${changePercent.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAreasToFocusCard() {
    final areasToFocus = _improvementData!['areas_to_focus'] as List<dynamic>;

    if (areasToFocus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text(
                  '🎯 Areas to Focus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...areasToFocus.map((area) {
              final pillar = area['pillar'] as String;
              final change = area['change'] as int;
              final changePercent = area['change_percent'] as double;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$pillar: $change points (${changePercent.toStringAsFixed(1)}%)',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningCorrelationCard() {
    final runningDynamics =
        _correlationData!['running_dynamics'] as Map<String, dynamic>;
    final correlations = _correlationData!['correlations'] as List<dynamic>;
    final insights = _correlationData!['insights'] as List<dynamic>;

    return Card(
      elevation: 4,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_run, color: Colors.blue, size: 28),
                SizedBox(width: 8),
                Text(
                  '🏃 Running → AISRI Correlation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Between assessments:',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildRunningStatRow(
                'Total Runs', runningDynamics['total_runs'].toString()),
            _buildRunningStatRow(
              'Pace Improvement',
              '${runningDynamics['pace_improvement_percent'].toStringAsFixed(1)}%',
            ),
            const Divider(height: 24),
            const Text(
              'Key Correlations:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...correlations.map((corr) {
              final pillar = corr['pillar'] as String;
              final correlation = corr['correlation'] as String;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        '$pillar: $correlation',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            const Text(
              '💡 Insights:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...insights.map((insight) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  insight as String,
                  style: const TextStyle(
                      fontSize: 13, fontStyle: FontStyle.italic),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard() {
    return Card(
      elevation: 4,
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.purple, size: 28),
                SizedBox(width: 8),
                Text(
                  '🎯 Next Steps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '✓ Continue your training plan',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '✓ Focus on exercises for the "Areas to Focus" pillars',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              '✓ Re-assess in 25 days to track ongoing progress',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
