import 'package:flutter/material.dart';
import 'dart:math' as math;

class AISRIDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> aisriData;
  final Map<String, dynamic> trainingPhase;
  final VoidCallback? onViewDetails;

  const AISRIDashboardWidget({
    super.key,
    required this.aisriData,
    required this.trainingPhase,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final pillarScores = aisriData['pillar_scores'] as Map<String, dynamic>;
    final aisriScore = aisriData['AISRI_score'] as int;
    final statusLabel = aisriData['status_label'] as String;
    final riskLevel = aisriData['risk_level'] as String;

    return Column(
      children: [
        // Main AISRI Score Card
        Card(
          elevation: 4,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getScoreColor(aisriScore),
                  _getScoreColor(aisriScore).withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // AISRI Score Circle
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: _CircularScorePainter(
                          score: aisriScore,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$aisriScore',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'AISRI',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Status and Risk Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: _getScoreColor(aisriScore),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.security, 'Risk Level',
                                riskLevel, Colors.white),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                                Icons.favorite,
                                'Recovery',
                                '${aisriData['recovery_score']}/100',
                                Colors.white),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                                Icons.trending_up,
                                'Zones',
                                '${(aisriData['allowed_zones'] as List).length}/6',
                                Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 6 Pillars Breakdown Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '6 Performance Pillars',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onViewDetails != null)
                      TextButton(
                        onPressed: onViewDetails,
                        child: const Text('View Details'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Pie Chart
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      // Custom Pie Chart
                      Expanded(
                        child: CustomPaint(
                          painter: _PillarPieChartPainter(
                            pillarScores: pillarScores,
                          ),
                        ),
                      ),

                      // Legend
                      SizedBox(
                        width: 140,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem('Running', '40%',
                                const Color(0xFF4A90E2), pillarScores['running']),
                            _buildLegendItem('Strength', '15%',
                                const Color(0xFFE74C3C), pillarScores['strength']),
                            _buildLegendItem('ROM', '12%',
                                const Color(0xFF9B59B6), pillarScores['rom']),
                            _buildLegendItem('Balance', '13%',
                                const Color(0xFF2ECC71), pillarScores['balance']),
                            _buildLegendItem('Mobility', '10%',
                                const Color(0xFFF39C12), pillarScores['mobility']),
                            _buildLegendItem('Alignment', '10%',
                                const Color(0xFF1ABC9C), pillarScores['alignment']),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Individual Pillar Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildPillarCard('Running', pillarScores['running'],
                        const Color(0xFF4A90E2), Icons.directions_run),
                    _buildPillarCard('Strength', pillarScores['strength'],
                        const Color(0xFFE74C3C), Icons.fitness_center),
                    _buildPillarCard('ROM', pillarScores['rom'],
                        const Color(0xFF9B59B6), Icons.accessibility_new),
                    _buildPillarCard('Balance', pillarScores['balance'],
                        const Color(0xFF2ECC71), Icons.balance),
                    _buildPillarCard('Mobility', pillarScores['mobility'],
                        const Color(0xFFF39C12), Icons.rotate_90_degrees_ccw),
                    _buildPillarCard('Alignment', pillarScores['alignment'],
                        const Color(0xFF1ABC9C), Icons.straighten),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Training Phase Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: Color(int.parse(
                          trainingPhase['color'].replaceAll('#', '0xFF'))),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phase ${trainingPhase['phase_number']}: ${trainingPhase['phase_name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: trainingPhase['progress_percent'] / 100,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(int.parse(trainingPhase['color']
                                  .replaceAll('#', '0xFF'))),
                              Color(int.parse(trainingPhase['color']
                                      .replaceAll('#', '0xFF')))
                                  .withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${trainingPhase['current_km'].toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(int.parse(
                            trainingPhase['color'].replaceAll('#', '0xFF'))),
                      ),
                    ),
                    Text(
                      '${trainingPhase['progress_percent']}% Complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  trainingPhase['focus'],
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 16),

                // Zone Distribution
                const Text(
                  'Weekly Zone Distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (trainingPhase['zone_distribution']
                          as Map<String, dynamic>)
                      .entries
                      .where((e) => e.value > 0)
                      .map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getZoneColor(entry.key)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getZoneColor(entry.key),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}%',
                        style: TextStyle(
                          color: _getZoneColor(entry.key),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
      String label, String weight, Color color, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard(
      String name, int score, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'AR':
        return const Color(0xFF87CEEB);
      case 'F':
        return const Color(0xFF4A90E2);
      case 'EN':
        return const Color(0xFF48D1CC);
      case 'TH':
        return const Color(0xFFFFA500);
      case 'P':
        return const Color(0xFFFF6B6B);
      case 'SP':
        return const Color(0xFF8B0000);
      default:
        return Colors.grey;
    }
  }
}

// Custom Painter for Circular Score
class _CircularScorePainter extends CustomPainter {
  final int score;
  final Color color;

  _CircularScorePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius - 6, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (score / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for Pie Chart
class _PillarPieChartPainter extends CustomPainter {
  final Map<String, dynamic> pillarScores;

  _PillarPieChartPainter({required this.pillarScores});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final pillars = [
      {'name': 'running', 'weight': 0.40, 'color': const Color(0xFF4A90E2)},
      {'name': 'strength', 'weight': 0.15, 'color': const Color(0xFFE74C3C)},
      {'name': 'rom', 'weight': 0.12, 'color': const Color(0xFF9B59B6)},
      {'name': 'balance', 'weight': 0.13, 'color': const Color(0xFF2ECC71)},
      {'name': 'mobility', 'weight': 0.10, 'color': const Color(0xFFF39C12)},
      {
        'name': 'alignment',
        'weight': 0.10,
        'color': const Color(0xFF1ABC9C)
      },
    ];

    double startAngle = -math.pi / 2;

    for (var pillar in pillars) {
      final weight = pillar['weight'] as double;
      final sweepAngle = 2 * math.pi * weight;
      final color = pillar['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle (donut effect)
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
