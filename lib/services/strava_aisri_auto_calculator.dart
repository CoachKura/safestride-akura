/// Strava-to-AISRI Auto Calculator
///
/// Automatically calculates AISRI scores from Strava activity data.
/// Analyzes running history, consistency, and performance trends to estimate:
/// - Running performance score
/// - Training consistency
/// - Fatigue indicators
/// - Recovery patterns
///
/// Use this when athlete connects Strava and you want to provide instant
/// assessment without manual form entry.

import 'dart:math';

class StravaAISRICalculator {
  /// Calculate AISRI score from Strava activity data
  ///
  /// Returns a map containing:
  /// - aisri_score: Overall score (0-100)
  /// - risk_level: 'Low', 'Moderate', or 'High'
  /// - pillar_scores: Individual pillar scores
  /// - confidence: How reliable the auto-calculation is (0-100)
  static Map<String, dynamic> calculateFromStrava({
    required Map<String, dynamic> athleteData,
    required List<Map<String, dynamic>> recentActivities,
    required Map<String, dynamic>? stats,
  }) {
    // Calculate each pillar from Strava data
    int adaptability = _calculateAdaptabilityFromStrava(
      athleteData: athleteData,
      activities: recentActivities,
    );

    int consistency = _calculateConsistencyFromStrava(
      activities: recentActivities,
    );

    int intensity = _calculateIntensityFromStrava(
      activities: recentActivities,
      stats: stats,
    );

    int recovery = _calculateRecoveryFromStrava(
      activities: recentActivities,
    );

    // For pillars we can't determine from Strava, use neutral/estimated scores
    int injuryRisk = 70; // Neutral-positive (can't assess from Strava alone)
    int fatigue = _estimateFatigueFromStrava(activities: recentActivities);

    // Calculate overall AISRI score
    int totalScore = ((adaptability +
                injuryRisk +
                fatigue +
                recovery +
                intensity +
                consistency) /
            6)
        .round();

    // Determine risk level
    String riskLevel;
    if (totalScore >= 80) {
      riskLevel = 'Low';
    } else if (totalScore >= 60) {
      riskLevel = 'Moderate';
    } else {
      riskLevel = 'High';
    }

    // Calculate confidence based on data availability
    int confidence = _calculateConfidence(
      athleteData: athleteData,
      activities: recentActivities,
      stats: stats,
    );

    return {
      'aisri_score': totalScore,
      'risk_level': riskLevel,
      'confidence': confidence,
      'pillar_adaptability': adaptability,
      'pillar_injury_risk': injuryRisk,
      'pillar_fatigue': fatigue,
      'pillar_recovery': recovery,
      'pillar_intensity': intensity,
      'pillar_consistency': consistency,
      'calculation_method': 'strava_auto',
      'activities_analyzed': recentActivities.length,
      'data_source': 'Strava',
      'notes': confidence < 70
          ? 'Limited activity data. Complete full assessment for more accurate scores.'
          : 'Auto-calculated from Strava. Complete full assessment for comprehensive analysis.',
    };
  }

  /// Pillar 1: Adaptability
  /// Based on years of running (from athlete join date), activity count, and progression
  static int _calculateAdaptabilityFromStrava({
    required Map<String, dynamic> athleteData,
    required List<Map<String, dynamic>> activities,
  }) {
    int score = 50; // Base score

    // Calculate training age (years since joined Strava as proxy for running experience)
    final createdAt = athleteData['created_at'] as String?;
    if (createdAt != null) {
      final joinDate = DateTime.parse(createdAt);
      final yearsActive = DateTime.now().difference(joinDate).inDays / 365;
      score += (yearsActive * 3).clamp(0, 20).toInt(); // Up to 20 bonus
    }

    // Activity count (more activities = better adaptation)
    final activityCount = activities.length;
    if (activityCount >= 30) {
      score += 20; // Consistent training
    } else if (activityCount >= 15) {
      score += 15;
    } else if (activityCount >= 5) {
      score += 10;
    } else {
      score += 5; // Limited data
    }

    // Training progression (check if distance is increasing)
    if (activities.length >= 4) {
      final recentAvg = activities
              .take(activities.length ~/ 2)
              .map((a) => (a['distance'] as num?) ?? 0)
              .reduce((a, b) => a + b) /
          (activities.length / 2);
      final olderAvg = activities
              .skip(activities.length ~/ 2)
              .map((a) => (a['distance'] as num?) ?? 0)
              .reduce((a, b) => a + b) /
          (activities.length / 2);

      if (recentAvg > olderAvg * 1.1) {
        score += 10; // Positive progression
      }
    }

    return score.clamp(0, 100);
  }

  /// Pillar 2: Consistency
  /// Based on training frequency and regularity over past 4 weeks
  static int _calculateConsistencyFromStrava({
    required List<Map<String, dynamic>> activities,
  }) {
    if (activities.isEmpty) return 30; // No data

    int score = 50; // Base score

    // Count activities per week for past 4 weeks
    final now = DateTime.now();
    final weekCounts = List<int>.filled(4, 0);

    for (var activity in activities) {
      final startDate = DateTime.parse(activity['start_date'] as String);
      final daysAgo = now.difference(startDate).inDays;

      if (daysAgo <= 7) {
        weekCounts[0]++;
      } else if (daysAgo <= 14) {
        weekCounts[1]++;
      } else if (daysAgo <= 21) {
        weekCounts[2]++;
      } else if (daysAgo <= 28) {
        weekCounts[3]++;
      }
    }

    // Calculate average weekly activities
    final avgWeekly = weekCounts.reduce((a, b) => a + b) / weekCounts.length;

    // Frequency bonus
    if (avgWeekly >= 6) {
      score += 30; // 6+ runs/week
    } else if (avgWeekly >= 4) {
      score += 25; // 4-5 runs/week
    } else if (avgWeekly >= 3) {
      score += 20; // 3 runs/week
    } else if (avgWeekly >= 2) {
      score += 10; // 2 runs/week
    }

    // Regularity bonus (consistency of weekly counts)
    final variance =
        weekCounts.map((c) => pow(c - avgWeekly, 2)).reduce((a, b) => a + b) /
            weekCounts.length;
    final stdDev = sqrt(variance);

    if (stdDev < 1) {
      score += 10; // Very consistent
    } else if (stdDev < 2) {
      score += 5; // Moderately consistent
    }

    return score.clamp(0, 100);
  }

  /// Pillar 3: Intensity
  /// Based on pace variability and heart rate zones (if available)
  static int _calculateIntensityFromStrava({
    required List<Map<String, dynamic>> activities,
    Map<String, dynamic>? stats,
  }) {
    if (activities.isEmpty) return 60; // Neutral score

    int score = 60; // Base score

    // Check pace variability (good training includes variety)
    final paces = activities
        .where((a) =>
            a['average_speed'] != null &&
            (a['average_speed'] as num) > 0 &&
            a['distance'] != null &&
            (a['distance'] as num) > 1000) // At least 1km
        .map((a) {
      final speedMps = (a['average_speed'] as num).toDouble();
      final paceMinPerKm = (1000 / 60) / speedMps; // min/km
      return paceMinPerKm;
    }).toList();

    if (paces.length >= 3) {
      final avgPace = paces.reduce((a, b) => a + b) / paces.length;
      final fastestPace = paces.reduce((a, b) => a < b ? a : b);
      final slowestPace = paces.reduce((a, b) => a > b ? a : b);

      final paceRange = slowestPace - fastestPace;

      // Good variety in training intensity
      if (paceRange > 2.0) {
        score += 20; // Excellent variety (>2 min/km difference)
      } else if (paceRange > 1.0) {
        score += 15; // Good variety
      } else if (paceRange > 0.5) {
        score += 10; // Moderate variety
      }

      // Check for very slow recovery runs (good sign)
      if (slowestPace > avgPace * 1.3) {
        score += 10; // Includes easy recovery runs
      }
    }

    // Check for recent high-intensity efforts
    final recentHard = activities.take(7).any((a) {
      final sufferScore = a['suffer_score'] as int?;
      return sufferScore != null && sufferScore > 100;
    });

    if (recentHard) {
      score += 10; // Recent quality session
    }

    return score.clamp(0, 100);
  }

  /// Pillar 4: Recovery
  /// Based on rest days and activity spacing
  static int _calculateRecoveryFromStrava({
    required List<Map<String, dynamic>> activities,
  }) {
    if (activities.isEmpty) return 60; // Neutral

    int score = 60; // Base score

    // Calculate rest days in past 2 weeks
    final now = DateTime.now();
    final past14Days = List<bool>.filled(14, false);

    for (var activity in activities) {
      final startDate = DateTime.parse(activity['start_date'] as String);
      final daysAgo = now.difference(startDate).inDays;

      if (daysAgo >= 0 && daysAgo < 14) {
        past14Days[daysAgo] = true;
      }
    }

    final restDays = past14Days.where((hasActivity) => !hasActivity).length;

    // Rest day scoring
    if (restDays >= 4) {
      score += 20; // Good recovery (4+ rest days per 2 weeks)
    } else if (restDays >= 2) {
      score += 15; // Moderate recovery
    } else if (restDays >= 1) {
      score += 10; // Minimal recovery
    } else {
      score -= 10; // No rest (overtraining risk)
    }

    // Check for consecutive training days (risks overtraining)
    int maxConsecutive = 0;
    int currentConsecutive = 0;

    for (var hasActivity in past14Days) {
      if (hasActivity) {
        currentConsecutive++;
        if (currentConsecutive > maxConsecutive) {
          maxConsecutive = currentConsecutive;
        }
      } else {
        currentConsecutive = 0;
      }
    }

    if (maxConsecutive > 10) {
      score -= 20; // Very concerning
    } else if (maxConsecutive > 7) {
      score -= 10; // Risky
    } else if (maxConsecutive <= 3) {
      score += 10; // Good spacing
    }

    return score.clamp(0, 100);
  }

  /// Pillar 5 (estimated): Fatigue
  /// Estimate from recent training load vs. average
  static int _estimateFatigueFromStrava({
    required List<Map<String, dynamic>> activities,
  }) {
    if (activities.isEmpty) return 60; // Neutral

    int score = 70; // Start optimistic

    // Compare recent week to average
    final now = DateTime.now();
    final recentWeekDistance = activities
        .where((a) {
          final startDate = DateTime.parse(a['start_date'] as String);
          return now.difference(startDate).inDays <= 7;
        })
        .map((a) => (a['distance'] as num?) ?? 0)
        .fold<num>(0, (sum, d) => sum + d);

    final avgWeeklyDistance = activities.isEmpty
        ? 0
        : activities
                .map((a) => (a['distance'] as num?) ?? 0)
                .fold<num>(0, (sum, d) => sum + d) /
            4; // Approximate 4 weeks

    if (recentWeekDistance > avgWeeklyDistance * 1.5) {
      score -= 20; // Significant overload
    } else if (recentWeekDistance > avgWeeklyDistance * 1.2) {
      score -= 10; // Moderate overload
    } else if (recentWeekDistance < avgWeeklyDistance * 0.7) {
      score += 10; // Good taper/recovery
    }

    return score.clamp(0, 100);
  }

  /// Calculate confidence level in the auto-generated score
  static int _calculateConfidence({
    required Map<String, dynamic> athleteData,
    required List<Map<String, dynamic>> activities,
    Map<String, dynamic>? stats,
  }) {
    int confidence = 50; // Base confidence

    // More activities = higher confidence
    if (activities.length >= 30) {
      confidence += 30;
    } else if (activities.length >= 15) {
      confidence += 20;
    } else if (activities.length >= 5) {
      confidence += 10;
    }

    // Athlete age on platform
    final createdAt = athleteData['created_at'] as String?;
    if (createdAt != null) {
      final joinDate = DateTime.parse(createdAt);
      final yearsActive = DateTime.now().difference(joinDate).inDays / 365;
      if (yearsActive >= 2) {
        confidence += 10;
      } else if (yearsActive >= 1) {
        confidence += 5;
      }
    }

    // Heart rate data availability
    final hasHRData = activities.any((a) => a['average_heartrate'] != null);
    if (hasHRData) {
      confidence += 10;
    }

    return confidence.clamp(0, 100);
  }
}
