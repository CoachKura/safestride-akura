class StravaAnalyzer {
  // Analyze Strava activities and identify areas needing improvement
  static StravaAnalysis analyzeActivities(
      List<Map<String, dynamic>> activities, Map<String, dynamic>? aisriData) {
    if (activities.isEmpty) {
      return StravaAnalysis.empty();
    }

    // Calculate average metrics
    double totalDistance = 0;
    double totalTime = 0;
    double totalCadence = 0;
    double totalHeartRate = 0;
    int cadenceCount = 0;
    int hrCount = 0;

    for (var activity in activities) {
      totalDistance += (activity['distance'] as num?)?.toDouble() ?? 0;
      totalTime += (activity['moving_time'] as num?)?.toDouble() ?? 0;

      if (activity['average_cadence'] != null) {
        totalCadence += (activity['average_cadence'] as num).toDouble() *
            2; // Strava reports half cadence
        cadenceCount++;
      }

      if (activity['average_heartrate'] != null) {
        totalHeartRate += (activity['average_heartrate'] as num).toDouble();
        hrCount++;
      }
    }

    final avgCadence = cadenceCount > 0 ? totalCadence / cadenceCount : 0.0;
    final avgHeartRate = hrCount > 0 ? totalHeartRate / hrCount : 0.0;
    final avgPace = totalTime > 0
        ? (totalTime / 60) / (totalDistance / 1000)
        : 0.0; // min/km
    final weeklyDistance = totalDistance / 1000; // km

    // Analyze AISRI data if available
    int? aisriScore;
    Map<String, int>? pillarScores;
    String? injuryHistory;

    if (aisriData != null) {
      aisriScore = aisriData['aisri_score'] as int?;
      pillarScores = {
        'mobility': aisriData['mobility_score'] as int? ?? 0,
        'strength': aisriData['strength_score'] as int? ?? 0,
        'balance': aisriData['balance_score'] as int? ?? 0,
        'flexibility': aisriData['flexibility_score'] as int? ?? 0,
        'endurance': aisriData['endurance_score'] as int? ?? 0,
        'power': aisriData['power_score'] as int? ?? 0,
      };
      injuryHistory = aisriData['injury_history'] as String?;
    }

    return StravaAnalysis(
      avgCadence: avgCadence.toDouble(),
      avgHeartRate: avgHeartRate.toDouble(),
      avgPace: avgPace.toDouble(),
      weeklyDistance: weeklyDistance,
      activitiesCount: activities.length,
      aisriScore: aisriScore,
      pillarScores: pillarScores,
      injuryHistory: injuryHistory,
    );
  }

  // Identify focus areas based on analysis
  static List<String> identifyFocusAreas(StravaAnalysis analysis) {
    List<String> focusAreas = [];

    // Low cadence = Need cadence work
    if (analysis.avgCadence > 0 && analysis.avgCadence < 170) {
      focusAreas.add('cadence');
    }

    // AISRI pillar weaknesses
    if (analysis.pillarScores != null) {
      final scores = analysis.pillarScores!;

      if (scores['mobility']! < 70) focusAreas.add('mobility');
      if (scores['strength']! < 70) focusAreas.add('strength');
      if (scores['balance']! < 70) focusAreas.add('balance');
      if (scores['flexibility']! < 70) focusAreas.add('flexibility');
    }

    // Injury history = Need prevention work
    if (analysis.injuryHistory != null && analysis.injuryHistory!.isNotEmpty) {
      focusAreas.add('injury_prevention');
    }

    // High volume = Need recovery
    if (analysis.weeklyDistance > 50) {
      focusAreas.add('recovery');
    }

    // If no specific issues, add general maintenance
    if (focusAreas.isEmpty) {
      focusAreas.addAll(['strength', 'mobility', 'balance']);
    }

    return focusAreas;
  }

  // Calculate injury risk level
  static String calculateInjuryRisk(StravaAnalysis analysis) {
    int riskScore = 0;

    // Low cadence increases risk
    if (analysis.avgCadence > 0 && analysis.avgCadence < 160) {
      riskScore += 30;
    } else if (analysis.avgCadence < 170) {
      riskScore += 15;
    }

    // AISRI score
    if (analysis.aisriScore != null) {
      if (analysis.aisriScore! < 50) {
        riskScore += 40;
      } else if (analysis.aisriScore! < 70) {
        riskScore += 20;
      } else if (analysis.aisriScore! < 85) {
        riskScore += 10;
      }
    }

    // High mileage without proper strength
    if (analysis.weeklyDistance > 50 &&
        (analysis.pillarScores?['strength'] ?? 100) < 70) {
      riskScore += 20;
    }

    // Injury history
    if (analysis.injuryHistory != null && analysis.injuryHistory!.isNotEmpty) {
      riskScore += 15;
    }

    if (riskScore >= 60) return 'high';
    if (riskScore >= 30) return 'moderate';
    return 'low';
  }
}

class StravaAnalysis {
  final double avgCadence;
  final double avgHeartRate;
  final double avgPace; // min/km
  final double weeklyDistance; // km
  final int activitiesCount;
  final int? aisriScore;
  final Map<String, int>? pillarScores;
  final String? injuryHistory;

  StravaAnalysis({
    required this.avgCadence,
    required this.avgHeartRate,
    required this.avgPace,
    required this.weeklyDistance,
    required this.activitiesCount,
    this.aisriScore,
    this.pillarScores,
    this.injuryHistory,
  });

  factory StravaAnalysis.empty() {
    return StravaAnalysis(
      avgCadence: 0,
      avgHeartRate: 0,
      avgPace: 0,
      weeklyDistance: 0,
      activitiesCount: 0,
    );
  }

  bool get hasData => activitiesCount > 0;

  String get cadenceStatus {
    if (avgCadence == 0) return 'Unknown';
    if (avgCadence < 160) return 'Low (needs improvement)';
    if (avgCadence < 170) return 'Below optimal';
    if (avgCadence < 180) return 'Good';
    return 'Optimal';
  }

  String get paceDisplay {
    if (avgPace == 0) return 'N/A';
    final minutes = avgPace.floor();
    final seconds = ((avgPace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  String get distanceDisplay {
    return '${weeklyDistance.toStringAsFixed(1)} km/week';
  }
}
