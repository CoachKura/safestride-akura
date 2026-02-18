// Biomechanics Analyzer Service
// Analyzes running form from device metrics
// Provides form efficiency scoring and recommendations

import 'dart:developer' as developer;

class BiomechanicsMetrics {
  final double? cadence; // steps per minute
  final double? groundContactTime; // milliseconds
  final double? verticalOscillation; // centimeters
  final double? strideLength; // meters
  final double? verticalRatio; // percentage
  final double? power; // watts (if available)
  final double? avgHeartRate; // bpm
  final double? avgPace; // seconds per km

  BiomechanicsMetrics({
    this.cadence,
    this.groundContactTime,
    this.verticalOscillation,
    this.strideLength,
    this.verticalRatio,
    this.power,
    this.avgHeartRate,
    this.avgPace,
  });

  factory BiomechanicsMetrics.fromActivity(Map<String, dynamic> activity) {
    return BiomechanicsMetrics(
      cadence: activity['avg_cadence']?.toDouble(),
      groundContactTime: activity['avg_ground_contact_time']?.toDouble(),
      verticalOscillation: activity['avg_vertical_oscillation']?.toDouble(),
      strideLength: activity['avg_stride_length']?.toDouble(),
      verticalRatio: activity['avg_vertical_ratio']?.toDouble(),
      power: activity['avg_power']?.toDouble(),
      avgHeartRate: activity['avg_heart_rate']?.toDouble(),
      avgPace: activity['avg_pace']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cadence': cadence,
      'ground_contact_time': groundContactTime,
      'vertical_oscillation': verticalOscillation,
      'stride_length': strideLength,
      'vertical_ratio': verticalRatio,
      'power': power,
      'avg_heart_rate': avgHeartRate,
      'avg_pace': avgPace,
    };
  }
}

class MetricAnalysis {
  final String metricName;
  final String status; // 'optimal', 'good', 'needs_improvement', 'poor'
  final String message;
  final String? target;
  final String? action;
  final double score; // 0-100

  MetricAnalysis({
    required this.metricName,
    required this.status,
    required this.message,
    this.target,
    this.action,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'metric_name': metricName,
      'status': status,
      'message': message,
      'target': target,
      'action': action,
      'score': score,
    };
  }
}

class BiomechanicsReport {
  final BiomechanicsMetrics metrics;
  final MetricAnalysis? cadenceAnalysis;
  final MetricAnalysis? gctAnalysis;
  final MetricAnalysis? voAnalysis;
  final MetricAnalysis? strideLengthAnalysis;
  final MetricAnalysis? verticalRatioAnalysis;
  final double formEfficiencyScore; // 0-100
  final String overallAssessment;
  final List<String> keyStrengths;
  final List<String> areasForImprovement;
  final List<String> recommendations;

  BiomechanicsReport({
    required this.metrics,
    this.cadenceAnalysis,
    this.gctAnalysis,
    this.voAnalysis,
    this.strideLengthAnalysis,
    this.verticalRatioAnalysis,
    required this.formEfficiencyScore,
    required this.overallAssessment,
    required this.keyStrengths,
    required this.areasForImprovement,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics.toJson(),
      'cadence_analysis': cadenceAnalysis?.toJson(),
      'gct_analysis': gctAnalysis?.toJson(),
      'vo_analysis': voAnalysis?.toJson(),
      'stride_length_analysis': strideLengthAnalysis?.toJson(),
      'vertical_ratio_analysis': verticalRatioAnalysis?.toJson(),
      'form_efficiency_score': formEfficiencyScore,
      'overall_assessment': overallAssessment,
      'key_strengths': keyStrengths,
      'areas_for_improvement': areasForImprovement,
      'recommendations': recommendations,
    };
  }
}

class BiomechanicsAnalyzer {
  // Analyze complete run biomechanics
  BiomechanicsReport analyzeRun(BiomechanicsMetrics metrics) {
    try {
      // Analyze each metric
      final cadenceAnalysis =
          metrics.cadence != null ? _analyzeCadence(metrics.cadence!) : null;

      final gctAnalysis = metrics.groundContactTime != null
          ? _analyzeGroundContactTime(metrics.groundContactTime!)
          : null;

      final voAnalysis = metrics.verticalOscillation != null
          ? _analyzeVerticalOscillation(metrics.verticalOscillation!)
          : null;

      final strideLengthAnalysis = metrics.strideLength != null
          ? _analyzeStrideLength(metrics.strideLength!, metrics.cadence)
          : null;

      final verticalRatioAnalysis = metrics.verticalRatio != null
          ? _analyzeVerticalRatio(metrics.verticalRatio!)
          : null;

      // Calculate form efficiency score
      final efficiencyScore = _calculateFormEfficiency(
        cadenceAnalysis,
        gctAnalysis,
        voAnalysis,
        verticalRatioAnalysis,
      );

      // Generate overall assessment
      final assessment = _generateOverallAssessment(efficiencyScore);

      // Identify strengths and areas for improvement
      final strengths = _identifyStrengths([
        cadenceAnalysis,
        gctAnalysis,
        voAnalysis,
        strideLengthAnalysis,
        verticalRatioAnalysis,
      ]);

      final improvements = _identifyImprovements([
        cadenceAnalysis,
        gctAnalysis,
        voAnalysis,
        strideLengthAnalysis,
        verticalRatioAnalysis,
      ]);

      // Generate recommendations
      final recommendations = _generateRecommendations(metrics, improvements);

      return BiomechanicsReport(
        metrics: metrics,
        cadenceAnalysis: cadenceAnalysis,
        gctAnalysis: gctAnalysis,
        voAnalysis: voAnalysis,
        strideLengthAnalysis: strideLengthAnalysis,
        verticalRatioAnalysis: verticalRatioAnalysis,
        formEfficiencyScore: efficiencyScore,
        overallAssessment: assessment,
        keyStrengths: strengths,
        areasForImprovement: improvements,
        recommendations: recommendations,
      );
    } catch (e) {
      developer.log('❌ Error analyzing biomechanics: $e');
      rethrow;
    }
  }

  // Analyze cadence (steps per minute)
  MetricAnalysis _analyzeCadence(double cadence) {
    if (cadence < 160) {
      return MetricAnalysis(
        metricName: 'Cadence',
        status: 'poor',
        message: 'Very low cadence increases injury risk',
        target: '170-180 spm',
        action: 'Increase by 5% each week using metronome app',
        score: 40,
      );
    } else if (cadence < 170) {
      return MetricAnalysis(
        metricName: 'Cadence',
        status: 'needs_improvement',
        message: 'Cadence is below optimal range',
        target: '170-180 spm',
        action: 'Focus on quicker, shorter strides',
        score: 65,
      );
    } else if (cadence >= 170 && cadence <= 185) {
      return MetricAnalysis(
        metricName: 'Cadence',
        status: 'optimal',
        message: 'Excellent cadence - maintain this range',
        target: '170-180 spm',
        action: 'Continue current form',
        score: 95,
      );
    } else if (cadence <= 195) {
      return MetricAnalysis(
        metricName: 'Cadence',
        status: 'good',
        message: 'Cadence is slightly high but acceptable',
        target: '170-180 spm',
        action: 'Consider relaxing stride slightly',
        score: 85,
      );
    } else {
      return MetricAnalysis(
        metricName: 'Cadence',
        status: 'needs_improvement',
        message: 'Very high cadence may indicate tension',
        target: '170-180 spm',
        action: 'Focus on relaxation and natural rhythm',
        score: 70,
      );
    }
  }

  // Analyze ground contact time (milliseconds)
  MetricAnalysis _analyzeGroundContactTime(double gct) {
    if (gct < 200) {
      return MetricAnalysis(
        metricName: 'Ground Contact Time',
        status: 'optimal',
        message: 'Very efficient ground contact - excellent form',
        target: '200-250 ms',
        action: 'Maintain current technique',
        score: 100,
      );
    } else if (gct <= 250) {
      return MetricAnalysis(
        metricName: 'Ground Contact Time',
        status: 'good',
        message: 'Good ground contact time',
        target: '200-250 ms',
        action: 'Continue current form',
        score: 90,
      );
    } else if (gct <= 280) {
      return MetricAnalysis(
        metricName: 'Ground Contact Time',
        status: 'needs_improvement',
        message: 'Ground contact time is elevated',
        target: '200-250 ms',
        action: 'Focus on quicker push-off, increase cadence',
        score: 70,
      );
    } else {
      return MetricAnalysis(
        metricName: 'Ground Contact Time',
        status: 'poor',
        message: 'Long ground contact increases injury risk',
        target: '200-250 ms',
        action: 'Work on plyometrics, increase cadence to 175+',
        score: 50,
      );
    }
  }

  // Analyze vertical oscillation (centimeters)
  MetricAnalysis _analyzeVerticalOscillation(double vo) {
    if (vo < 7.0) {
      return MetricAnalysis(
        metricName: 'Vertical Oscillation',
        status: 'optimal',
        message: 'Excellent - minimal vertical bounce',
        target: '6-10 cm',
        action: 'Maintain smooth, efficient form',
        score: 100,
      );
    } else if (vo <= 10.0) {
      return MetricAnalysis(
        metricName: 'Vertical Oscillation',
        status: 'good',
        message: 'Good vertical oscillation',
        target: '6-10 cm',
        action: 'Continue current form',
        score: 90,
      );
    } else if (vo <= 12.0) {
      return MetricAnalysis(
        metricName: 'Vertical Oscillation',
        status: 'needs_improvement',
        message: 'Moderate bounce - room for improvement',
        target: '6-10 cm',
        action: 'Focus on running "lighter", shorter strides',
        score: 70,
      );
    } else {
      return MetricAnalysis(
        metricName: 'Vertical Oscillation',
        status: 'poor',
        message: 'High vertical bounce - wasting energy',
        target: '6-10 cm',
        action: 'Focus on forward motion, not upward. Shorter strides.',
        score: 50,
      );
    }
  }

  // Analyze stride length
  MetricAnalysis _analyzeStrideLength(double strideLength, double? cadence) {
    final optimalRange =
        cadence != null ? _calculateOptimalStrideLength(cadence) : '1.0-1.3 m';

    if (strideLength < 0.9) {
      return MetricAnalysis(
        metricName: 'Stride Length',
        status: 'needs_improvement',
        message: 'Very short stride - may limit speed',
        target: optimalRange,
        action: 'Work on hip flexibility and power',
        score: 65,
      );
    } else if (strideLength >= 0.9 && strideLength <= 1.3) {
      return MetricAnalysis(
        metricName: 'Stride Length',
        status: 'optimal',
        message: 'Optimal stride length for efficiency',
        target: optimalRange,
        action: 'Maintain current form',
        score: 95,
      );
    } else if (strideLength <= 1.5) {
      return MetricAnalysis(
        metricName: 'Stride Length',
        status: 'needs_improvement',
        message: 'Stride is getting long - overstriding risk',
        target: optimalRange,
        action: 'Shorten stride, increase cadence',
        score: 70,
      );
    } else {
      return MetricAnalysis(
        metricName: 'Stride Length',
        status: 'poor',
        message: 'Overstriding - high injury risk',
        target: optimalRange,
        action: 'Reduce stride length immediately, increase cadence',
        score: 45,
      );
    }
  }

  // Analyze vertical ratio
  MetricAnalysis _analyzeVerticalRatio(double ratio) {
    if (ratio < 6.0) {
      return MetricAnalysis(
        metricName: 'Vertical Ratio',
        status: 'optimal',
        message: 'Excellent vertical ratio - very efficient',
        target: '<8%',
        action: 'Maintain current technique',
        score: 100,
      );
    } else if (ratio <= 8.0) {
      return MetricAnalysis(
        metricName: 'Vertical Ratio',
        status: 'good',
        message: 'Good vertical ratio',
        target: '<8%',
        action: 'Continue current form',
        score: 90,
      );
    } else if (ratio <= 10.0) {
      return MetricAnalysis(
        metricName: 'Vertical Ratio',
        status: 'needs_improvement',
        message: 'Moderate efficiency loss',
        target: '<8%',
        action: 'Focus on forward propulsion',
        score: 70,
      );
    } else {
      return MetricAnalysis(
        metricName: 'Vertical Ratio',
        status: 'poor',
        message: 'High energy waste on vertical movement',
        target: '<8%',
        action: 'Work on form drills, reduce bounce',
        score: 50,
      );
    }
  }

  // Calculate optimal stride length based on cadence
  String _calculateOptimalStrideLength(double cadence) {
    // Rough estimate: stride length varies with speed and cadence
    final minStride = (1.0).toStringAsFixed(1);
    final maxStride = (1.3).toStringAsFixed(1);
    return '$minStride-$maxStride m';
  }

  // Calculate form efficiency score (0-100)
  double _calculateFormEfficiency(
    MetricAnalysis? cadence,
    MetricAnalysis? gct,
    MetricAnalysis? vo,
    MetricAnalysis? verticalRatio,
  ) {
    final scores = <double>[];

    if (cadence != null) scores.add(cadence.score);
    if (gct != null) scores.add(gct.score);
    if (vo != null) scores.add(vo.score);
    if (verticalRatio != null) scores.add(verticalRatio.score);

    if (scores.isEmpty) return 0;

    return scores.reduce((a, b) => a + b) / scores.length;
  }

  // Generate overall assessment
  String _generateOverallAssessment(double score) {
    if (score >= 90) {
      return 'Excellent running form - keep up the great work!';
    } else if (score >= 80) {
      return 'Very good form with minor areas for improvement';
    } else if (score >= 70) {
      return 'Good form but several areas need attention';
    } else if (score >= 60) {
      return 'Form needs improvement to reduce injury risk';
    } else {
      return 'Form requires significant attention - consider coaching';
    }
  }

  // Identify strengths
  List<String> _identifyStrengths(List<MetricAnalysis?> analyses) {
    final strengths = <String>[];

    for (final analysis in analyses) {
      if (analysis != null &&
          (analysis.status == 'optimal' || analysis.status == 'good')) {
        strengths.add('${analysis.metricName}: ${analysis.message}');
      }
    }

    if (strengths.isEmpty) {
      strengths.add('Room for improvement across all metrics');
    }

    return strengths;
  }

  // Identify areas for improvement
  List<String> _identifyImprovements(List<MetricAnalysis?> analyses) {
    final improvements = <String>[];

    for (final analysis in analyses) {
      if (analysis != null &&
          (analysis.status == 'needs_improvement' ||
              analysis.status == 'poor')) {
        improvements.add('${analysis.metricName}: ${analysis.message}');
      }
    }

    return improvements;
  }

  // Generate recommendations
  List<String> _generateRecommendations(
    BiomechanicsMetrics metrics,
    List<String> improvements,
  ) {
    final recommendations = <String>[];

    // Cadence recommendations
    if (metrics.cadence != null && metrics.cadence! < 170) {
      recommendations.add(
        '🔄 Increase cadence: Use a metronome app at ${(metrics.cadence! * 1.03).toStringAsFixed(0)} spm for 3-5 weeks',
      );
    }

    // Ground contact time recommendations
    if (metrics.groundContactTime != null && metrics.groundContactTime! > 250) {
      recommendations.add(
        '⚡ Improve ground contact: Plyometric drills 2x/week (jump rope, box jumps)',
      );
    }

    // Vertical oscillation recommendations
    if (metrics.verticalOscillation != null &&
        metrics.verticalOscillation! > 10) {
      recommendations.add(
        '🎯 Reduce bounce: Focus on "running quieter", shorter ground contact',
      );
    }

    // General recommendations
    if (improvements.length >= 3) {
      recommendations.add(
        '👟 Consider form analysis: Work with running coach or use video analysis',
      );
    }

    recommendations.add(
      '📊 Track progress: Re-assess biomechanics in 4 weeks',
    );

    return recommendations;
  }

  // Compare two runs
  Map<String, dynamic> compareBiomechanics(
    BiomechanicsMetrics run1,
    BiomechanicsMetrics run2,
  ) {
    final improvements = <String>[];
    final regressions = <String>[];

    // Compare cadence
    if (run1.cadence != null && run2.cadence != null) {
      final diff = run2.cadence! - run1.cadence!;
      if (diff.abs() > 2) {
        if (diff > 0) {
          improvements
              .add('Cadence improved by ${diff.toStringAsFixed(1)} spm');
        } else {
          regressions
              .add('Cadence decreased by ${diff.abs().toStringAsFixed(1)} spm');
        }
      }
    }

    // Compare ground contact time
    if (run1.groundContactTime != null && run2.groundContactTime != null) {
      final diff = run2.groundContactTime! - run1.groundContactTime!;
      if (diff.abs() > 5) {
        if (diff < 0) {
          improvements.add(
              'Ground contact time reduced by ${diff.abs().toStringAsFixed(0)} ms');
        } else {
          regressions.add(
              'Ground contact time increased by ${diff.toStringAsFixed(0)} ms');
        }
      }
    }

    // Compare vertical oscillation
    if (run1.verticalOscillation != null && run2.verticalOscillation != null) {
      final diff = run2.verticalOscillation! - run1.verticalOscillation!;
      if (diff.abs() > 0.5) {
        if (diff < 0) {
          improvements.add(
              'Vertical oscillation reduced by ${diff.abs().toStringAsFixed(1)} cm');
        } else {
          regressions.add(
              'Vertical oscillation increased by ${diff.toStringAsFixed(1)} cm');
        }
      }
    }

    return {
      'improvements': improvements,
      'regressions': regressions,
      'overall':
          improvements.length > regressions.length ? 'improving' : 'stable',
    };
  }
}
