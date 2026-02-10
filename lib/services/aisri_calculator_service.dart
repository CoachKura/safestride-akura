
/// AISRI (AI-powered Sports Running Intelligence) Calculator Service
/// Implements the economical runner philosophy with 6-pillar assessment
class AISRICalculatorService {
  /// Calculate AISRI Score (0-100) based on 6 pillars
  /// Formula: AISRI = (Weighted HRV Ã— 0.3) + (Recovery Status Ã— 0.3) +
  ///          (Load History Ã— 0.2) + (Sleep Quality Ã— 0.1) + (Subjective Feel Ã— 0.1)
  static Map<String, dynamic> calculateAISRIScore({
    required int age,
    required double weightKg,
    required double heightCm,
    required Map<String, dynamic> recentWorkouts,
    required Map<String, dynamic> injuryHistory,
    required Map<String, dynamic> sleepData,
    required Map<String, dynamic> assessmentData,
    int? subjectiveFeel, // 1-10 scale
  }) {
    // Calculate 6 Pillars (each 0-100)
    final runningPerformance = _calculateRunningPillar(recentWorkouts, age);
    final strength = _calculateStrengthPillar(assessmentData);
    final rom = _calculateROMPillar(assessmentData);
    final balance = _calculateBalancePillar(assessmentData);
    final mobility = _calculateMobilityPillar(assessmentData);
    final alignment = _calculateAlignmentPillar(assessmentData);

    // Weighted AISRI calculation
    final pillarScores = {
      'running_performance': runningPerformance,
      'strength': strength,
      'rom': rom,
      'balance': balance,
      'mobility': mobility,
      'alignment': alignment,
    };

    // AISRI = weighted sum of pillars
    final aisriScore = (
      (runningPerformance * 0.40) + // 40%
      (strength * 0.15) +           // 15%
      (rom * 0.12) +                // 12%
      (balance * 0.13) +            // 13%
      (mobility * 0.10) +           // 10%
      (alignment * 0.10)            // 10%
    ).round().clamp(0, 100);

    // Calculate recovery metrics
    final recoveryScore = _calculateRecoveryScore(
      sleepData: sleepData,
      recentWorkouts: recentWorkouts,
      injuryHistory: injuryHistory,
    );

    // Calculate training load (7-day and 28-day)
    final loadMetrics = _calculateLoadMetrics(recentWorkouts);

    return {
      'aisri_score': aisriScore,
      'pillar_scores': pillarScores,
      'recovery_score': recoveryScore,
      'weekly_load': loadMetrics['weekly_load'],
      'monthly_load': loadMetrics['monthly_load'],
      'load_ratio': loadMetrics['load_ratio'], // Acute:Chronic
      'risk_level': _determineRiskLevel(aisriScore),
      'status_label': _getStatusLabel(aisriScore),
      'allowed_zones': _getAllowedZones(aisriScore, pillarScores),
      'safety_gates': _checkSafetyGates(
        aisriScore: aisriScore,
        pillarScores: pillarScores,
        injuryHistory: injuryHistory,
        loadMetrics: loadMetrics,
      ),
    };
  }

  /// Calculate Running Performance Pillar (40% weight)
  static int _calculateRunningPillar(Map<String, dynamic> workouts, int age) {
    if (workouts.isEmpty) return 50; // Default

    final recentRuns = workouts['recent_runs'] as List? ?? [];
    if (recentRuns.isEmpty) return 50;

    // Factors: consistency, pace improvement, volume progression
    final consistency = _calculateConsistency(recentRuns);
    final paceImprovement = _calculatePaceImprovement(recentRuns);
    final volumeProgression = _calculateVolumeProgression(recentRuns);

    return ((consistency * 0.4) + (paceImprovement * 0.3) + (volumeProgression * 0.3))
        .round()
        .clamp(0, 100);
  }

  static int _calculateConsistency(List recentRuns) {
    // Last 4 weeks: 3-5 runs/week = optimal
    if (recentRuns.length < 4) return 40;
    if (recentRuns.length >= 12 && recentRuns.length <= 20) return 90;
    if (recentRuns.length >= 8) return 75;
    return 60;
  }

  static int _calculatePaceImprovement(List recentRuns) {
    if (recentRuns.length < 3) return 50;
    
    // Compare recent pace vs older pace
    final recentAvg = recentRuns.take(3).fold<double>(
      0.0, (sum, run) => sum + (run['avg_pace'] ?? 6.0)) / 3;
    final olderAvg = recentRuns.skip(3).take(3).fold<double>(
      0.0, (sum, run) => sum + (run['avg_pace'] ?? 6.0)) / 3;
    
    if (olderAvg == 0) return 50;
    final improvement = ((olderAvg - recentAvg) / olderAvg) * 100;
    
    if (improvement > 5) return 90; // Improving
    if (improvement > 0) return 75;
    if (improvement > -5) return 60; // Stable
    return 40; // Declining
  }

  static int _calculateVolumeProgression(List recentRuns) {
    // Progressive overload: 10% rule
    if (recentRuns.length < 8) return 50;
    
    final lastWeek = recentRuns.take(7).fold<double>(
      0.0, (sum, run) => sum + ((run['distance'] ?? run['distance_km']) ?? 0.0));
    final previousWeek = recentRuns.skip(7).take(7).fold<double>(
      0.0, (sum, run) => sum + ((run['distance'] ?? run['distance_km']) ?? 0.0));
    
    if (previousWeek == 0) return 50;
    final increase = ((lastWeek - previousWeek) / previousWeek) * 100;
    
    if (increase > 20) return 40; // Too aggressive
    if (increase >= 5 && increase <= 15) return 90; // Ideal
    if (increase >= 0 && increase < 5) return 75; // Gradual
    if (increase >= -5) return 70; // Maintenance
    return 50; // Decreasing
  }

  /// Calculate Strength Pillar (15% weight)
  static int _calculateStrengthPillar(Map<String, dynamic> assessment) {
    final lowerBodyStrength = assessment['single_leg_squat_score'] ?? 50;
    final coreStrength = assessment['plank_time_score'] ?? 50;
    final calfRaises = assessment['calf_raise_score'] ?? 50;

    return ((lowerBodyStrength * 0.5) + (coreStrength * 0.3) + (calfRaises * 0.2))
        .round()
        .clamp(0, 100);
  }

  /// Calculate ROM (Range of Motion) Pillar (12% weight)
  static int _calculateROMPillar(Map<String, dynamic> assessment) {
    final ankleDorsiflexion = assessment['ankle_dorsiflexion_score'] ?? 50;
    final hipFlexion = assessment['hip_flexion_score'] ?? 50;
    final hipExtension = assessment['hip_extension_score'] ?? 50;

    return ((ankleDorsiflexion * 0.4) + (hipFlexion * 0.3) + (hipExtension * 0.3))
        .round()
        .clamp(0, 100);
  }

  /// Calculate Balance Pillar (13% weight)
  static int _calculateBalancePillar(Map<String, dynamic> assessment) {
    final singleLegBalance = assessment['single_leg_balance_score'] ?? 50;
    final stabilityTest = assessment['stability_test_score'] ?? 50;

    return ((singleLegBalance * 0.6) + (stabilityTest * 0.4))
        .round()
        .clamp(0, 100);
  }

  /// Calculate Mobility Pillar (10% weight)
  static int _calculateMobilityPillar(Map<String, dynamic> assessment) {
    final hipMobility = assessment['hip_mobility_score'] ?? 50;
    final thoracicSpine = assessment['thoracic_spine_score'] ?? 50;

    return ((hipMobility * 0.6) + (thoracicSpine * 0.4))
        .round()
        .clamp(0, 100);
  }

  /// Calculate Alignment Pillar (10% weight)
  static int _calculateAlignmentPillar(Map<String, dynamic> assessment) {
    final kneeDrop = assessment['knee_drop_score'] ?? 50;
    final pelvicAlignment = assessment['pelvic_alignment_score'] ?? 50;

    return ((kneeDrop * 0.5) + (pelvicAlignment * 0.5))
        .round()
        .clamp(0, 100);
  }

  /// Calculate Recovery Score
  static int _calculateRecoveryScore({
    required Map<String, dynamic> sleepData,
    required Map<String, dynamic> recentWorkouts,
    required Map<String, dynamic> injuryHistory,
  }) {
    final sleepScore = _calculateSleepScore(sleepData);
    final fatigueScore = _calculateFatigueScore(recentWorkouts);
    final injuryImpact = _calculateInjuryImpact(injuryHistory);

    return ((sleepScore * 0.4) + (fatigueScore * 0.4) + (injuryImpact * 0.2))
        .round()
        .clamp(0, 100);
  }

  static int _calculateSleepScore(Map<String, dynamic> sleepData) {
    final avgHours = sleepData['avg_hours'] ?? 7.0;
    final quality = sleepData['quality_rating'] ?? 7; // 1-10

    if (avgHours >= 7 && avgHours <= 9 && quality >= 7) return 90;
    if (avgHours >= 6 && avgHours < 7 && quality >= 6) return 70;
    if (avgHours >= 5) return 50;
    return 30;
  }

  static int _calculateFatigueScore(Map<String, dynamic> workouts) {
    final recentRuns = workouts['recent_runs'] as List? ?? [];
    if (recentRuns.isEmpty) return 80;

    // Last 7 days total load
    final last7Days = recentRuns.take(7).fold<double>(
      0.0, (sum, run) => sum + (run['distance_km'] ?? 0.0));

    if (last7Days < 20) return 90; // Well recovered
    if (last7Days < 40) return 80;
    if (last7Days < 60) return 65;
    if (last7Days < 80) return 50;
    return 35; // Fatigued
  }

  static int _calculateInjuryImpact(Map<String, dynamic> injuryHistory) {
    final activeInjuries = injuryHistory['active_injuries'] as List? ?? [];
    if (activeInjuries.isEmpty) return 100;

    final maxSeverity = activeInjuries.fold<int>(
      0, (max, inj) => (inj['severity'] as int? ?? 0) > max ? inj['severity'] : max);

    if (maxSeverity >= 8) return 20; // Severe
    if (maxSeverity >= 6) return 40; // Moderate
    if (maxSeverity >= 4) return 60; // Minor
    return 80; // Very minor
  }

  /// Calculate Load Metrics (Acute:Chronic ratio)
  static Map<String, dynamic> _calculateLoadMetrics(Map<String, dynamic> workouts) {
    final recentRuns = workouts['recent_runs'] as List? ?? [];

    final last7Days = recentRuns.take(7).fold<double>(
      0.0, (sum, run) => sum + ((run['distance'] ?? run['distance_km']) ?? 0.0));
    
    final last28Days = recentRuns.take(28).fold<double>(
      0.0, (sum, run) => sum + ((run['distance'] ?? run['distance_km']) ?? 0.0));

    final chronicLoad = last28Days / 4; // 4-week average
    final loadRatio = chronicLoad > 0 ? last7Days / chronicLoad : 1.0;

    return {
      'weekly_load': last7Days,
      'monthly_load': last28Days,
      'load_ratio': loadRatio,
      'load_status': _getLoadStatus(loadRatio),
    };
  }

  static String _getLoadStatus(double ratio) {
    if (ratio < 0.8) return 'Detraining';
    if (ratio >= 0.8 && ratio <= 1.3) return 'Optimal';
    if (ratio > 1.3 && ratio <= 1.5) return 'High Risk';
    return 'Very High Risk';
  }

  /// Determine allowed HR zones based on AISRI score
  static List<String> _getAllowedZones(int aisriScore, Map<String, dynamic> pillarScores) {
    if (aisriScore >= 85) return ['AR', 'F', 'EN', 'TH', 'P', 'SP'];
    if (aisriScore >= 70) return ['AR', 'F', 'EN', 'TH', 'P'];
    if (aisriScore >= 55) return ['AR', 'F', 'EN', 'TH'];
    if (aisriScore >= 40) return ['AR', 'F', 'EN'];
    return ['AR', 'F'];
  }

  /// Check Safety Gates for Power and Speed zones
  static Map<String, dynamic> _checkSafetyGates({
    required int aisriScore,
    required Map<String, dynamic> pillarScores,
    required Map<String, dynamic> injuryHistory,
    required Map<String, dynamic> loadMetrics,
  }) {
    final activeInjuries = injuryHistory['active_injuries'] as List? ?? [];
    final hasRecentInjury = activeInjuries.isNotEmpty;
    final romScore = pillarScores['rom'] ?? 0;

    // Power Zone (P) Requirements
    final powerUnlocked = aisriScore >= 70 &&
        romScore >= 75 &&
        !hasRecentInjury &&
        loadMetrics['load_ratio'] <= 1.3;

    // Speed Zone (SP) Requirements
    final allPillarsHigh = pillarScores.values.every((score) => score >= 75);
    final speedUnlocked = aisriScore >= 75 &&
        allPillarsHigh &&
        !hasRecentInjury &&
        loadMetrics['load_ratio'] <= 1.2;

    return {
      'power_zone_unlocked': powerUnlocked,
      'speed_zone_unlocked': speedUnlocked,
      'power_requirements': {
        'aisri_met': aisriScore >= 70,
        'rom_met': romScore >= 75,
        'no_injury_met': !hasRecentInjury,
        'load_ratio_met': loadMetrics['load_ratio'] <= 1.3,
      },
      'speed_requirements': {
        'aisri_met': aisriScore >= 75,
        'all_pillars_met': allPillarsHigh,
        'no_injury_met': !hasRecentInjury,
        'load_ratio_met': loadMetrics['load_ratio'] <= 1.2,
      },
    };
  }

  /// Calculate HR zones based on age
  static Map<String, dynamic> calculateHRZones(int age) {
    final maxHR = 208 - (0.7 * age);

    return {
      'max_hr': maxHR.round(),
      'zones': {
        'AR': {
          'name': 'Active Recovery',
          'min': (maxHR * 0.50).round(),
          'max': (maxHR * 0.60).round(),
          'purpose': 'Recovery, Warm-up, Cool-down',
          'color': '#87CEEB', // Light blue
        },
        'F': {
          'name': 'Foundation',
          'min': (maxHR * 0.60).round(),
          'max': (maxHR * 0.70).round(),
          'purpose': 'Aerobic Base, Fat Burning, Stamina',
          'color': '#4A90E2', // Blue
        },
        'EN': {
          'name': 'Endurance',
          'min': (maxHR * 0.70).round(),
          'max': (maxHR * 0.80).round(),
          'purpose': 'Aerobic Fitness, Improved Oxygen Efficiency',
          'color': '#48D1CC', // Turquoise
        },
        'TH': {
          'name': 'Threshold',
          'min': (maxHR * 0.80).round(),
          'max': (maxHR * 0.87).round(),
          'purpose': 'Lactate Threshold, Anaerobic Capacity, Speed Endurance',
          'color': '#FFA500', // Orange
          'is_core': true,
        },
        'P': {
          'name': 'Power',
          'min': (maxHR * 0.87).round(),
          'max': (maxHR * 0.95).round(),
          'purpose': 'Max Oxygen Uptake (VO2 Max), Peak Performance',
          'color': '#FF6B6B', // Red
          'requires_gate': true,
        },
        'SP': {
          'name': 'Speed',
          'min': (maxHR * 0.95).round(),
          'max': maxHR.round(),
          'purpose': 'Anaerobic Power, Sprinting, Short Bursts',
          'color': '#8B0000', // Dark red
          'requires_gate': true,
        },
      },
    };
  }

  static String _determineRiskLevel(int score) {
    if (score >= 80) return 'Low Risk';
    if (score >= 60) return 'Moderate Risk';
    if (score >= 40) return 'High Risk';
    return 'Very High Risk';
  }

  static String _getStatusLabel(int score) {
    if (score >= 85) return 'Elite';
    if (score >= 70) return 'Advanced+';
    if (score >= 55) return 'Advanced';
    if (score >= 40) return 'Intermediate';
    return 'Beginner';
  }
}
