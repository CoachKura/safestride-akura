// Comprehensive workout data analysis service
// Analyzes Strava/GPS data and identifies issues with remedies

import 'package:flutter/material.dart';

class WorkoutAnalysisService {
  /// Analyzes workout data and returns detailed findings
  static WorkoutAnalysis analyzeWorkoutData({
    required Map<String, dynamic> workoutData,
    required Map<String, dynamic> aisriData,
    required List<Map<String, dynamic>> stravaActivities,
  }) {
    List<AnalysisIssue> issues = [];
    List<String> strengths = [];
    Map<String, dynamic> metrics = {};

    // Extract key metrics
    final avgCadence = _calculateAverageCadence(stravaActivities);
    final avgHeartRate = _calculateAverageHeartRate(stravaActivities);
    final weeklyDistance = _calculateWeeklyDistance(stravaActivities);
    final avgPace = _calculateAveragePace(stravaActivities);
    final verticalOscillation = _calculateVerticalOscillation(stravaActivities);
    final groundContactTime = _calculateGroundContactTime(stravaActivities);
    final trainingLoad = _calculateTrainingLoad(stravaActivities);
    final recoveryScore = aisriData['recovery_score'] ?? 0;
    final injuryRisk = aisriData['score'] ?? 0;

    metrics = {
      'avgCadence': avgCadence,
      'avgHeartRate': avgHeartRate,
      'weeklyDistance': weeklyDistance,
      'avgPace': avgPace,
      'verticalOscillation': verticalOscillation,
      'groundContactTime': groundContactTime,
      'trainingLoad': trainingLoad,
      'recoveryScore': recoveryScore,
      'injuryRisk': injuryRisk,
    };

    // ANALYSIS 1: Cadence Analysis
    if (avgCadence < 160) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.critical,
        category: 'Cadence',
        title: 'Critically Low Cadence',
        currentValue: '${avgCadence.toStringAsFixed(0)} spm',
        targetValue: '170-180 spm',
        problem:
            'Your cadence of ${avgCadence.toStringAsFixed(0)} spm is significantly below optimal range. '
            'Low cadence increases ground contact time, leading to higher impact forces on joints.',
        why:
            'When stride rate is too low, you spend more time on the ground with each step, '
            'increasing vertical loading forces by up to 30%. This dramatically increases injury risk, '
            'particularly for shin splints, stress fractures, and knee pain.',
        remedy:
            '1. Practice high-cadence drills: 30-second intervals at 180+ spm\n'
            '2. Use a metronome app during easy runs\n'
            '3. Focus on quick foot turnover, not stride length\n'
            '4. Start with 5% cadence increase per week',
        protocolFocus: [
          'Cadence Drills',
          'Plyometric Exercises',
          'Rhythm Training'
        ],
      ));
    } else if (avgCadence < 170) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.warning,
        category: 'Cadence',
        title: 'Below Optimal Cadence',
        currentValue: '${avgCadence.toStringAsFixed(0)} spm',
        targetValue: '170-180 spm',
        problem:
            'Your cadence is below the optimal range for injury prevention.',
        why:
            'Elite runners maintain 170-180 spm to minimize impact forces and improve efficiency.',
        remedy:
            'Gradually increase cadence through focused drills and metronome training.',
        protocolFocus: ['Cadence Awareness Drills'],
      ));
    } else if (avgCadence >= 170 && avgCadence <= 185) {
      strengths.add(
          '✅ Excellent cadence (${avgCadence.toStringAsFixed(0)} spm) - optimal for injury prevention');
    }

    // ANALYSIS 2: Vertical Oscillation (VO)
    if (verticalOscillation > 10.0) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.critical,
        category: 'Running Form',
        title: 'Excessive Vertical Oscillation',
        currentValue: '${verticalOscillation.toStringAsFixed(1)} cm',
        targetValue: '6-8 cm',
        problem:
            'Your vertical oscillation (bounce) of ${verticalOscillation.toStringAsFixed(1)} cm is excessive. '
            'You are wasting significant energy moving up and down instead of forward.',
        why:
            'High vertical oscillation (>10cm) indicates poor running economy and increased impact loading. '
            'Each bounce creates a landing impact of 2-3x body weight. With excessive bounce, you\'re essentially '
            'jumping with every step instead of gliding forward. This leads to:\n'
            '• Increased stress on joints (knees, ankles, hips)\n'
            '• Higher energy cost (you get tired faster)\n'
            '• Greater risk of overuse injuries\n'
            '• Reduced running efficiency by 5-10%',
        remedy:
            '1. Core strengthening: Planks, dead bugs, bird dogs (3x/week)\n'
            '2. Glute activation: Clamshells, bridges, single-leg squats\n'
            '3. Running form drills: High knees, butt kicks, A-skips\n'
            '4. Lean slightly forward from ankles (not hips)\n'
            '5. Focus on "quiet" running - land softly\n'
            '6. Shorten stride length, increase turnover',
        protocolFocus: [
          'Core Stability',
          'Running Form Correction',
          'Glute Strengthening'
        ],
      ));
    } else if (verticalOscillation > 8.5) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.warning,
        category: 'Running Form',
        title: 'Above Optimal Vertical Oscillation',
        currentValue: '${verticalOscillation.toStringAsFixed(1)} cm',
        targetValue: '6-8 cm',
        problem: 'Your bounce is slightly high, reducing running efficiency.',
        why: 'Optimal VO reduces wasted energy and impact forces.',
        remedy: 'Focus on forward lean, core engagement, and glute activation.',
        protocolFocus: ['Running Form Drills', 'Core Work'],
      ));
    } else if (verticalOscillation >= 6.0 && verticalOscillation <= 8.5) {
      strengths.add(
          '✅ Optimal vertical oscillation (${verticalOscillation.toStringAsFixed(1)} cm) - excellent form');
    }

    // ANALYSIS 3: Ground Contact Time (GCT)
    if (groundContactTime > 280) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.critical,
        category: 'Running Biomechanics',
        title: 'Excessive Ground Contact Time',
        currentValue: '${groundContactTime.toStringAsFixed(0)} ms',
        targetValue: '200-250 ms',
        problem:
            'Your foot stays on the ground too long (${groundContactTime.toStringAsFixed(0)} ms), '
            'increasing injury risk and reducing speed.',
        why: 'Prolonged ground contact time indicates:\n'
            '• Weak spring mechanism in tendons and muscles\n'
            '• Poor reactive strength (plyometric deficit)\n'
            '• Excessive braking forces with each stride\n'
            '• Higher cumulative loading stress on joints\n'
            'Every millisecond over 250ms adds unnecessary stress cycles.',
        remedy: '1. Plyometric training: Box jumps, jump rope, bounding\n'
            '2. Calf strengthening: Single-leg calf raises (3x15 reps)\n'
            '3. Ankle mobility: Dorsiflexion stretches\n'
            '4. Quick foot drills: Ladder drills, fast feet\n'
            '5. Barefoot running on grass (short sessions)',
        protocolFocus: [
          'Plyometrics',
          'Calf Strengthening',
          'Reactive Strength'
        ],
      ));
    } else if (groundContactTime > 260) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.warning,
        category: 'Running Biomechanics',
        title: 'Above Optimal Ground Contact Time',
        currentValue: '${groundContactTime.toStringAsFixed(0)} ms',
        targetValue: '200-250 ms',
        problem: 'Ground contact time is slightly elevated.',
        why:
            'Improving reactive strength will enhance performance and reduce injury risk.',
        remedy: 'Incorporate plyometric exercises and calf strengthening.',
        protocolFocus: ['Plyometrics', 'Ankle Strength'],
      ));
    } else if (groundContactTime >= 200 && groundContactTime <= 260) {
      strengths.add(
          '✅ Excellent ground contact time (${groundContactTime.toStringAsFixed(0)} ms)');
    }

    // ANALYSIS 4: Training Load & Recovery
    if (trainingLoad > 500 && recoveryScore < 60) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.critical,
        category: 'Recovery',
        title: 'Inadequate Recovery for Training Load',
        currentValue: 'Load: $trainingLoad, Recovery: $recoveryScore%',
        targetValue: 'Recovery: 70-85%',
        problem:
            'High training load with poor recovery is a red flag for overtraining and injury.',
        why: 'When training load exceeds recovery capacity:\n'
            '• Muscle tissue doesn\'t repair properly\n'
            '• Chronic inflammation builds up\n'
            '• Immune system weakens\n'
            '• Injury risk increases by 3-4x\n'
            '• Performance plateaus or declines',
        remedy: '1. Add 1-2 complete rest days per week\n'
            '2. Sleep 8+ hours consistently\n'
            '3. Reduce training volume by 20-30% for 1 week\n'
            '4. Active recovery: Swimming, cycling, yoga\n'
            '5. Nutrition: Increase protein to 1.6g/kg bodyweight\n'
            '6. Foam rolling and stretching daily',
        protocolFocus: ['Active Recovery', 'Mobility Work', 'Reduced Volume'],
      ));
    } else if (trainingLoad > 400 && recoveryScore < 70) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.warning,
        category: 'Recovery',
        title: 'Recovery Lagging Behind Training Load',
        currentValue: 'Recovery: $recoveryScore%',
        targetValue: '70-85%',
        problem:
            'Your recovery score is not keeping pace with training demands.',
        why:
            'Suboptimal recovery reduces adaptation and increases injury risk.',
        remedy: 'Prioritize sleep, nutrition, and add one extra rest day.',
        protocolFocus: ['Recovery Strategies'],
      ));
    } else if (recoveryScore >= 70) {
      strengths.add('✅ Good recovery status ($recoveryScore%)');
    }

    // ANALYSIS 5: Weekly Distance Management
    if (weeklyDistance > 60 && injuryRisk < 60) {
      issues.add(AnalysisIssue(
        severity: IssueSeverity.warning,
        category: 'Volume Management',
        title: 'High Volume with Elevated Injury Risk',
        currentValue: '${weeklyDistance.toStringAsFixed(1)} km/week',
        targetValue: 'Reduce by 10-15%',
        problem:
            'Your weekly distance combined with low AISRI score indicates overload.',
        why:
            'High volume without adequate structural readiness leads to overuse injuries.',
        remedy:
            'Reduce weekly volume by 10-15% until AISRI score improves above 65.',
        protocolFocus: ['Volume Reduction', 'Strengthening'],
      ));
    } else if (weeklyDistance >= 30 && weeklyDistance <= 60) {
      strengths.add(
          '✅ Appropriate weekly distance (${weeklyDistance.toStringAsFixed(1)} km)');
    }

    // ANALYSIS 6: Heart Rate Zones (if available)
    if (avgHeartRate > 0) {
      // Assuming max HR of 220 - age (use 190 as example)
      final hrPercentage = (avgHeartRate / 190) * 100;
      if (hrPercentage > 85) {
        issues.add(AnalysisIssue(
          severity: IssueSeverity.warning,
          category: 'Training Intensity',
          title: 'Excessive Training Intensity',
          currentValue:
              '${avgHeartRate.toStringAsFixed(0)} bpm (${hrPercentage.toStringAsFixed(0)}% max)',
          targetValue: '70-80% max HR for base building',
          problem: 'You are training too hard too often.',
          why:
              'Constantly high heart rate indicates inadequate easy running, leading to burnout.',
          remedy:
              'Follow 80/20 rule: 80% easy (conversational pace), 20% hard efforts.',
          protocolFocus: ['Easy Run Focus', 'Pace Discipline'],
        ));
      }
    }

    // Calculate overall risk score
    final riskScore = _calculateOverallRisk(issues, injuryRisk);

    return WorkoutAnalysis(
      issues: issues,
      strengths: strengths,
      metrics: metrics,
      overallRiskScore: riskScore,
      recommendations: _generateRecommendations(issues),
    );
  }

  // Helper: Calculate average cadence from Strava activities
  static double _calculateAverageCadence(
      List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return 0;

    double totalCadence = 0;
    int count = 0;

    for (var activity in activities) {
      if (activity['cadence'] != null) {
        totalCadence += activity['cadence'];
        count++;
      }
    }

    return count > 0 ? totalCadence / count : 165; // Default if no data
  }

  static double _calculateAverageHeartRate(
      List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return 0;

    double total = 0;
    int count = 0;

    for (var activity in activities) {
      if (activity['average_heartrate'] != null) {
        total += activity['average_heartrate'];
        count++;
      }
    }

    return count > 0 ? total / count : 0;
  }

  static double _calculateWeeklyDistance(
      List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return 0;

    double total = 0;
    for (var activity in activities) {
      if (activity['distance'] != null) {
        total += activity['distance'] / 1000; // Convert to km
      }
    }

    return total;
  }

  static double _calculateAveragePace(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return 0;

    double totalTime = 0;
    double totalDistance = 0;

    for (var activity in activities) {
      if (activity['moving_time'] != null && activity['distance'] != null) {
        totalTime += activity['moving_time'];
        totalDistance += activity['distance'];
      }
    }

    return totalDistance > 0 ? totalTime / totalDistance : 0;
  }

  static double _calculateVerticalOscillation(
      List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return 8.0; // Default moderate value

    double total = 0;
    int count = 0;

    for (var activity in activities) {
      if (activity['vertical_oscillation'] != null) {
        total += activity['vertical_oscillation'];
        count++;
      }
    }

    // If no VO data, estimate based on cadence
    if (count == 0) {
      final avgCadence = _calculateAverageCadence(activities);
      if (avgCadence < 160) return 11.5; // High VO estimate
      if (avgCadence < 170) return 9.2;
      return 7.5;
    }

    return total / count;
  }

  static double _calculateGroundContactTime(
      List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return 250; // Default moderate value

    double total = 0;
    int count = 0;

    for (var activity in activities) {
      if (activity['ground_contact_time'] != null) {
        total += activity['ground_contact_time'];
        count++;
      }
    }

    // If no GCT data, estimate based on cadence
    if (count == 0) {
      final avgCadence = _calculateAverageCadence(activities);
      if (avgCadence < 160) return 290; // High GCT estimate
      if (avgCadence < 170) return 265;
      return 235;
    }

    return total / count;
  }

  static double _calculateTrainingLoad(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return 0;

    double load = 0;
    for (var activity in activities) {
      final distance = activity['distance'] ?? 0;
      final time = activity['moving_time'] ?? 0;
      final elevation = activity['total_elevation_gain'] ?? 0;

      // Simple load calculation: distance + time factor + elevation factor
      load += (distance / 1000) * 10 + (time / 3600) * 5 + (elevation * 0.1);
    }

    return load;
  }

  static int _calculateOverallRisk(
      List<AnalysisIssue> issues, int baseInjuryRisk) {
    int criticalCount =
        issues.where((i) => i.severity == IssueSeverity.critical).length;
    int warningCount =
        issues.where((i) => i.severity == IssueSeverity.warning).length;

    int riskAdjustment = (criticalCount * 15) + (warningCount * 5);
    int finalRisk = baseInjuryRisk - riskAdjustment;

    return finalRisk.clamp(0, 100);
  }

  static List<String> _generateRecommendations(List<AnalysisIssue> issues) {
    List<String> recommendations = [];

    // Priority recommendations based on critical issues
    final criticalIssues =
        issues.where((i) => i.severity == IssueSeverity.critical).toList();

    if (criticalIssues.isNotEmpty) {
      recommendations.add(
          '🚨 URGENT: Address ${criticalIssues.length} critical issue(s) immediately');

      for (var issue in criticalIssues) {
        recommendations.add('• ${issue.category}: ${issue.title}');
      }
    }

    return recommendations;
  }
}

// Analysis result model
class WorkoutAnalysis {
  final List<AnalysisIssue> issues;
  final List<String> strengths;
  final Map<String, dynamic> metrics;
  final int overallRiskScore;
  final List<String> recommendations;

  WorkoutAnalysis({
    required this.issues,
    required this.strengths,
    required this.metrics,
    required this.overallRiskScore,
    required this.recommendations,
  });

  List<AnalysisIssue> get criticalIssues =>
      issues.where((i) => i.severity == IssueSeverity.critical).toList();

  List<AnalysisIssue> get warningIssues =>
      issues.where((i) => i.severity == IssueSeverity.warning).toList();

  bool get hasCriticalIssues => criticalIssues.isNotEmpty;
}

// Individual analysis issue
class AnalysisIssue {
  final IssueSeverity severity;
  final String category;
  final String title;
  final String currentValue;
  final String targetValue;
  final String problem;
  final String why;
  final String remedy;
  final List<String> protocolFocus;

  AnalysisIssue({
    required this.severity,
    required this.category,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.problem,
    required this.why,
    required this.remedy,
    required this.protocolFocus,
  });

  Color get severityColor {
    switch (severity) {
      case IssueSeverity.critical:
        return Colors.red;
      case IssueSeverity.warning:
        return Colors.orange;
      case IssueSeverity.info:
        return Colors.blue;
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case IssueSeverity.critical:
        return Icons.error;
      case IssueSeverity.warning:
        return Icons.warning;
      case IssueSeverity.info:
        return Icons.info;
    }
  }
}

enum IssueSeverity {
  critical,
  warning,
  info,
}
