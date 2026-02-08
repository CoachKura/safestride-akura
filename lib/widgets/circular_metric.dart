// lib/widgets/circular_metric.dart
// Circular metric widgets for displaying progress

import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularMetric extends StatelessWidget {
  final double value;
  final double goal;
  final String label;
  final List<Color> colors;
  final double size;
  final String? unit;

  const CircularMetric({
    super.key,
    required this.value,
    required this.goal,
    required this.label,
    required this.colors,
    this.size = 100,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: CircularProgressPainter(
            progress: progress,
            colors: colors,
            strokeWidth: size * 0.08,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatValue(value),
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (unit != null)
                    Text(
                      unit!,
                      style: TextStyle(
                        fontSize: size * 0.10,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: size * 0.08),
        Text(
          label,
          style: TextStyle(
            fontSize: size * 0.11,
            color: Colors.grey[400],
          ),
        ),
        Text(
          'Goal: ',
          style: TextStyle(
            fontSize: size * 0.09,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value >= 10000) {
      return 'k';
    } else if (value >= 1000) {
      return 'k';
    }
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi),
      colors: [...colors, colors.first],
      stops: [0.0, 0.5, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.colors != colors;
  }
}

/// Small circular metric for compact displays
class CircularMetricSmall extends StatelessWidget {
  final double value;
  final double goal;
  final IconData icon;
  final List<Color> colors;
  final double size;

  const CircularMetricSmall({
    super.key,
    required this.value,
    required this.goal,
    required this.icon,
    required this.colors,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;

    return CustomPaint(
      size: Size(size, size),
      painter: CircularProgressPainter(
        progress: progress,
        colors: colors,
        strokeWidth: size * 0.1,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon,
            size: size * 0.4,
            color: colors.first,
          ),
        ),
      ),
    );
  }
}
