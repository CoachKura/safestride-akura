/// AISRI Improvement Calculator
///
/// Tracks progress between assessments and calculates improvement scores.
/// Shows how each pillar has changed over time.
///
/// Features:
/// - Compare current vs previous assessment
/// - Calculate improvement percentage
/// - Identify strongest improvements
/// - Correlate with running dynamics
/// - 25-day reminder system

import 'package:supabase_flutter/supabase_flutter.dart';

class AISRIImprovementCalculator {
  /// Calculate improvement between two assessments
  ///
  /// Returns:
  /// - overall_improvement: Total score change
  /// - pillar_changes: Individual pillar improvements
  /// - biggest_gains: Pillars with most improvement
  /// - areas_to_focus: Pillars that declined
  static Future<Map<String, dynamic>> calculateImprovement({
    required String userId,
  }) async {
    // Fetch last 2 assessments
    final assessments = await Supabase.instance.client
        .from('aisri_assessments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(2);

    if (assessments.length < 2) {
      return {
        'has_previous': false,
        'message':
            'Complete another assessment in 25 days to track improvement!',
      };
    }

    final current = assessments[0];
    final previous = assessments[1];

    // Calculate days between assessments
    final currentDate = DateTime.parse(current['created_at'] as String);
    final previousDate = DateTime.parse(previous['created_at'] as String);
    final daysBetween = currentDate.difference(previousDate).inDays;

    // Overall AISRI score change
    final currentScore = current['AISRI_score'] as int;
    final previousScore = previous['AISRI_score'] as int;
    final overallChange = currentScore - previousScore;
    final overallChangePercent =
        ((overallChange / previousScore) * 100).toStringAsFixed(1);

    // Pillar changes
    final pillars = [
      'pillar_adaptability',
      'pillar_injury_risk',
      'pillar_fatigue',
      'pillar_recovery',
      'pillar_intensity',
      'pillar_consistency',
      'pillar_agility', // NEW PILLAR
    ];

    final pillarChanges = <String, Map<String, dynamic>>{};
    for (var pillar in pillars) {
      final currentVal = current[pillar] as int? ?? 0;
      final previousVal = previous[pillar] as int? ?? 0;
      final change = currentVal - previousVal;
      final changePercent = previousVal > 0
          ? ((change / previousVal) * 100).toStringAsFixed(1)
          : '0.0';

      pillarChanges[pillar] = {
        'current': currentVal,
        'previous': previousVal,
        'change': change,
        'change_percent': changePercent,
        'status': change > 0
            ? 'improved'
            : change < 0
                ? 'declined'
                : 'unchanged',
      };
    }

    // Identify biggest gains and areas to focus
    final sorted = pillarChanges.entries.toList()
      ..sort((a, b) =>
          (b.value['change'] as int).compareTo(a.value['change'] as int));

    final biggestGains = sorted
        .where((e) => (e.value['change'] as int) > 0)
        .take(3)
        .map((e) => {
              'pillar': e.key.replaceAll('pillar_', '').replaceAll('_', ' '),
              'change': e.value['change'],
              'change_percent': e.value['change_percent'],
            })
        .toList();

    final areasToFocus = sorted
        .where((e) => (e.value['change'] as int) < 0)
        .map((e) => {
              'pillar': e.key.replaceAll('pillar_', '').replaceAll('_', ' '),
              'change': e.value['change'],
              'change_percent': e.value['change_percent'],
            })
        .toList();

    return {
      'has_previous': true,
      'days_between': daysBetween,
      'overall': {
        'current_score': currentScore,
        'previous_score': previousScore,
        'change': overallChange,
        'change_percent': overallChangePercent,
        'status': overallChange > 0
            ? 'improved'
            : overallChange < 0
                ? 'declined'
                : 'unchanged',
      },
      'pillar_changes': pillarChanges,
      'biggest_gains': biggestGains,
      'areas_to_focus': areasToFocus,
      'assessment_dates': {
        'current': currentDate.toIso8601String(),
        'previous': previousDate.toIso8601String(),
      },
    };
  }

  /// Correlate running dynamics improvements with AISRI pillars
  ///
  /// Shows how better running performance affects injury risk scores
  static Future<Map<String, dynamic>> correlateWithRunningDynamics({
    required String userId,
    required String stravaAthleteId,
  }) async {
    // Fetch improvement data
    final improvement = await calculateImprovement(userId: userId);
    if (!improvement['has_previous']) {
      return {
        'has_correlation': false,
        'message': 'Need multiple assessments to show correlation',
      };
    }

    // Fetch Strava activities for the period between assessments
    final previousDate =
        DateTime.parse(improvement['assessment_dates']['previous'] as String);
    final currentDate =
        DateTime.parse(improvement['assessment_dates']['current'] as String);

    // Query activities between assessments
    final activities = await Supabase.instance.client
        .from('strava_activities')
        .select()
        .eq('athlete_id', stravaAthleteId)
        .gte('start_date', previousDate.toIso8601String())
        .lte('start_date', currentDate.toIso8601String())
        .order('start_date', ascending: false);

    if (activities.isEmpty) {
      return {
        'has_correlation': false,
        'message': 'No activities found in this period',
      };
    }

    // Calculate running dynamics improvements
    final totalRuns = activities.length;
    final totalDistance = activities.fold<double>(
      0,
      (sum, a) => sum + ((a['distance'] as num?) ?? 0) / 1000,
    );

    final avgPaces = activities
        .where((a) =>
            a['average_speed'] != null && (a['average_speed'] as num) > 0)
        .map((a) {
      final speedMps = (a['average_speed'] as num).toDouble();
      return (1000 / 60) / speedMps; // min/km
    }).toList();

    final avgPace = avgPaces.isNotEmpty
        ? avgPaces.reduce((a, b) => a + b) / avgPaces.length
        : 0.0;

    final paceImprovement =
        avgPaces.length >= 2 ? _calculatePaceImprovement(avgPaces) : 0.0;

    // Correlate with pillar improvements
    final consistencyChange =
        improvement['pillar_changes']['pillar_consistency']['change'] as int;
    final fatigueChange =
        improvement['pillar_changes']['pillar_fatigue']['change'] as int;
    final recoveryChange =
        improvement['pillar_changes']['pillar_recovery']['change'] as int;
    final intensityChange =
        improvement['pillar_changes']['pillar_intensity']['change'] as int;

    return {
      'has_correlation': true,
      'running_dynamics': {
        'total_runs': totalRuns,
        'total_distance_km': totalDistance.toStringAsFixed(1),
        'avg_pace_min_per_km': avgPace.toStringAsFixed(2),
        'pace_improvement_percent': paceImprovement.toStringAsFixed(1),
      },
      'correlations': [
        {
          'pillar': 'Consistency',
          'change': consistencyChange,
          'correlation': totalRuns >= 20
              ? 'High training frequency improved consistency score'
              : 'Increase training frequency to boost consistency',
        },
        {
          'pillar': 'Intensity',
          'change': intensityChange,
          'correlation': paceImprovement > 0
              ? 'Faster paces indicate better intensity management'
              : 'Focus on interval training to improve intensity',
        },
        {
          'pillar': 'Recovery',
          'change': recoveryChange,
          'correlation': recoveryChange > 0
              ? 'Improved recovery allows for better training'
              : 'Ensure adequate rest days between hard efforts',
        },
        {
          'pillar': 'Fatigue',
          'change': fatigueChange,
          'correlation': fatigueChange > 0
              ? 'Better fatigue management from smart training'
              : 'Monitor weekly volume to reduce fatigue',
        },
      ],
      'insights': _generateInsights(
        paceImprovement: paceImprovement,
        totalRuns: totalRuns,
        consistencyChange: consistencyChange,
        intensityChange: intensityChange,
      ),
    };
  }

  static double _calculatePaceImprovement(List<double> paces) {
    if (paces.length < 4) return 0.0;

    // Compare first half vs second half of period
    final firstHalf = paces.skip(paces.length ~/ 2).toList();
    final secondHalf = paces.take(paces.length ~/ 2).toList();

    final avgFirst = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final avgSecond = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    // Negative change = faster pace = improvement
    return ((avgFirst - avgSecond) / avgFirst) * 100;
  }

  static List<String> _generateInsights({
    required double paceImprovement,
    required int totalRuns,
    required int consistencyChange,
    required int intensityChange,
  }) {
    final insights = <String>[];

    if (paceImprovement > 5) {
      insights.add(
          '🎉 Your pace improved by ${paceImprovement.toStringAsFixed(1)}%! This shows your training is working.');
    }

    if (totalRuns >= 20 && consistencyChange > 0) {
      insights.add(
          '💪 $totalRuns runs with improved consistency - you\'re building a solid foundation!');
    }

    if (intensityChange > 5) {
      insights.add(
          '⚡ Better intensity management is reducing injury risk. Keep balancing hard and easy days.');
    }

    if (consistencyChange < 0) {
      insights.add(
          '⚠️ Consistency declined. Try to maintain regular training even with lower volume.');
    }

    if (insights.isEmpty) {
      insights.add(
          'Keep training consistently and you\'ll see improvements in your next assessment!');
    }

    return insights;
  }

  /// Check if 25-day reminder is due
  static Future<bool> shouldRemindReassessment(String userId) async {
    try {
      final lastAssessment = await Supabase.instance.client
          .from('aisri_assessments')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastAssessment == null) return false;

      final lastDate = DateTime.parse(lastAssessment['created_at'] as String);
      final daysSince = DateTime.now().difference(lastDate).inDays;

      return daysSince >= 25;
    } catch (e) {
      return false;
    }
  }
}
