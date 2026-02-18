// ML Injury Prediction Service
// AI/ML-based injury risk assessment and prediction
// Analyzes biomechanics, training load, and AISRI data

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

enum InjuryType {
  itBandSyndrome,
  shinSplints,
  plantarFasciitis,
  runnersKnee,
  achillesTendinopathy,
  stressFracture,
  hamstringStrain,
}

enum RiskLevel {
  low, // 0-30
  moderate, // 31-60
  high, // 61-80
  veryHigh, // 81-100
}

class InjuryRiskAssessment {
  final InjuryType injuryType;
  final double riskScore; // 0-100
  final RiskLevel riskLevel;
  final String timeToOnset;
  final List<String> preventionActions;
  final List<String> riskFactors;
  final Map<String, dynamic>? biomechanicsData;

  InjuryRiskAssessment({
    required this.injuryType,
    required this.riskScore,
    required this.riskLevel,
    required this.timeToOnset,
    required this.preventionActions,
    required this.riskFactors,
    this.biomechanicsData,
  });

  String get injuryName => _injuryTypeNames[injuryType] ?? 'Unknown Injury';

  static const Map<InjuryType, String> _injuryTypeNames = {
    InjuryType.itBandSyndrome: 'IT Band Syndrome',
    InjuryType.shinSplints: 'Shin Splints (MTSS)',
    InjuryType.plantarFasciitis: 'Plantar Fasciitis',
    InjuryType.runnersKnee: "Runner's Knee (PFPS)",
    InjuryType.achillesTendinopathy: 'Achilles Tendinopathy',
    InjuryType.stressFracture: 'Stress Fracture',
    InjuryType.hamstringStrain: 'Hamstring Strain',
  };

  Map<String, dynamic> toJson() {
    return {
      'injury_type': injuryType.name,
      'injury_name': injuryName,
      'risk_score': riskScore,
      'risk_level': riskLevel.name,
      'time_to_onset': timeToOnset,
      'prevention_actions': preventionActions,
      'risk_factors': riskFactors,
      'biomechanics_data': biomechanicsData,
    };
  }
}

class MLInjuryPredictionService {
  final _supabase = Supabase.instance.client;

  // Get comprehensive injury risk profile
  Future<List<InjuryRiskAssessment>> getInjuryRiskProfile(String userId) async {
    try {
      // Get user data
      final userData = await _getUserData(userId);
      final activityData = await _getRecentActivityData(userId, days: 28);
      final aisriData = await _getLatestAISRIData(userId);

      // Predict all injury types
      final predictions = <InjuryRiskAssessment>[];

      predictions.add(await predictITBandRisk(
        userId: userId,
        userData: userData,
        activityData: activityData,
        aisriData: aisriData,
      ));

      predictions.add(await predictShinSplintsRisk(
        userId: userId,
        userData: userData,
        activityData: activityData,
        aisriData: aisriData,
      ));

      predictions.add(await predictPlantarFasciitisRisk(
        userId: userId,
        userData: userData,
        activityData: activityData,
        aisriData: aisriData,
      ));

      predictions.add(await predictRunnersKneeRisk(
        userId: userId,
        userData: userData,
        activityData: activityData,
        aisriData: aisriData,
      ));

      predictions.add(await predictAchillesTendinopathyRisk(
        userId: userId,
        userData: userData,
        activityData: activityData,
        aisriData: aisriData,
      ));

      // Sort by risk score (highest first)
      predictions.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      // Save predictions to database
      await _savePredictions(userId, predictions);

      return predictions;
    } catch (e) {
      developer.log('❌ Error getting injury risk profile: $e');
      return [];
    }
  }

  // IT Band Syndrome Prediction
  Future<InjuryRiskAssessment> predictITBandRisk({
    required String userId,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? activityData,
    Map<String, dynamic>? aisriData,
  }) async {
    double riskScore = 0.0;
    final riskFactors = <String>[];

    // Weekly mileage increase (>10% = high risk)
    final weeklyIncrease = activityData?['weekly_mileage_increase'] ?? 0.0;
    if (weeklyIncrease > 0.15) {
      riskScore += 30;
      riskFactors.add(
          'Rapid mileage increase (${(weeklyIncrease * 100).toStringAsFixed(0)}%)');
    } else if (weeklyIncrease > 0.10) {
      riskScore += 20;
      riskFactors.add(
          'Moderate mileage increase (${(weeklyIncrease * 100).toStringAsFixed(0)}%)');
    }

    // Low cadence (<170 spm)
    final cadence = activityData?['avg_cadence'] ?? 175.0;
    if (cadence < 165) {
      riskScore += 25;
      riskFactors.add('Very low cadence (${cadence.toStringAsFixed(0)} spm)');
    } else if (cadence < 170) {
      riskScore += 15;
      riskFactors.add('Low cadence (${cadence.toStringAsFixed(0)} spm)');
    }

    // Excessive hill running (>30%)
    final hillPercentage = activityData?['hill_percentage'] ?? 0.0;
    if (hillPercentage > 0.30) {
      riskScore += 20;
      riskFactors.add(
          'High hill running (${(hillPercentage * 100).toStringAsFixed(0)}%)');
    }

    // Insufficient rest days (<1 per week)
    final restDays = activityData?['rest_days_per_week'] ?? 2;
    if (restDays < 1) {
      riskScore += 25;
      riskFactors.add('Insufficient rest (${restDays} days/week)');
    } else if (restDays < 2) {
      riskScore += 10;
      riskFactors.add('Limited rest (${restDays} days/week)');
    }

    // AISRI hip weakness indicators
    if (aisriData?['hip_weakness'] == true) {
      riskScore += 20;
      riskFactors.add('Hip weakness detected in AISRI');
    }

    // Previous IT band issues
    if (aisriData?['history_it_band'] == true) {
      riskScore += 15;
      riskFactors.add('Previous IT band injury');
    }

    riskScore = riskScore.clamp(0, 100);
    final riskLevel = _getRiskLevel(riskScore);
    final timeToOnset = _estimateTimeToOnset(riskScore);

    return InjuryRiskAssessment(
      injuryType: InjuryType.itBandSyndrome,
      riskScore: riskScore,
      riskLevel: riskLevel,
      timeToOnset: timeToOnset,
      riskFactors: riskFactors,
      preventionActions: _getITBandPreventionActions(riskScore),
    );
  }

  // Shin Splints Prediction
  Future<InjuryRiskAssessment> predictShinSplintsRisk({
    required String userId,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? activityData,
    Map<String, dynamic>? aisriData,
  }) async {
    double riskScore = 0.0;
    final riskFactors = <String>[];

    // Long ground contact time (>250ms)
    final gct = activityData?['avg_ground_contact_time'] ?? 240.0;
    if (gct > 270) {
      riskScore += 30;
      riskFactors
          .add('Very long ground contact time (${gct.toStringAsFixed(0)}ms)');
    } else if (gct > 250) {
      riskScore += 20;
      riskFactors.add('Long ground contact time (${gct.toStringAsFixed(0)}ms)');
    }

    // Low cadence (<170)
    final cadence = activityData?['avg_cadence'] ?? 175.0;
    if (cadence < 165) {
      riskScore += 25;
      riskFactors.add('Very low cadence (${cadence.toStringAsFixed(0)} spm)');
    } else if (cadence < 170) {
      riskScore += 15;
      riskFactors.add('Low cadence (${cadence.toStringAsFixed(0)} spm)');
    }

    // Rapid mileage increase
    final weeklyIncrease = activityData?['weekly_mileage_increase'] ?? 0.0;
    if (weeklyIncrease > 0.10) {
      riskScore += 25;
      riskFactors.add('Rapid training increase');
    }

    // Hard surfaces (concrete)
    if (activityData?['surface_type'] == 'concrete') {
      riskScore += 20;
      riskFactors.add('Running on hard surfaces');
    }

    // AISRI ankle/calf weakness
    if (aisriData?['calf_weakness'] == true) {
      riskScore += 20;
      riskFactors.add('Calf weakness detected');
    }

    // Previous shin splints
    if (aisriData?['history_shin_splints'] == true) {
      riskScore += 15;
      riskFactors.add('Previous shin splints');
    }

    riskScore = riskScore.clamp(0, 100);

    return InjuryRiskAssessment(
      injuryType: InjuryType.shinSplints,
      riskScore: riskScore,
      riskLevel: _getRiskLevel(riskScore),
      timeToOnset: _estimateTimeToOnset(riskScore),
      riskFactors: riskFactors,
      preventionActions: _getShinSplintsPreventionActions(riskScore),
    );
  }

  // Plantar Fasciitis Prediction
  Future<InjuryRiskAssessment> predictPlantarFasciitisRisk({
    required String userId,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? activityData,
    Map<String, dynamic>? aisriData,
  }) async {
    double riskScore = 0.0;
    final riskFactors = <String>[];

    // Long stride length
    final strideLength = activityData?['avg_stride_length'] ?? 1.2;
    if (strideLength > 1.4) {
      riskScore += 25;
      riskFactors
          .add('Long stride length (${strideLength.toStringAsFixed(2)}m)');
    }

    // High weekly mileage
    final weeklyMileage = activityData?['weekly_mileage'] ?? 0;
    if (weeklyMileage > 80) {
      riskScore += 20;
      riskFactors.add('High weekly mileage (${weeklyMileage}km)');
    }

    // Rapid volume increase
    final volumeIncrease = activityData?['weekly_mileage_increase'] ?? 0.0;
    if (volumeIncrease > 0.10) {
      riskScore += 20;
      riskFactors.add('Rapid volume increase');
    }

    // AISRI arch issues
    if (aisriData?['arch_issues'] == true) {
      riskScore += 25;
      riskFactors.add('Arch support issues detected');
    }

    // Previous plantar fasciitis
    if (aisriData?['history_plantar_fasciitis'] == true) {
      riskScore += 20;
      riskFactors.add('Previous plantar fasciitis');
    }

    riskScore = riskScore.clamp(0, 100);

    return InjuryRiskAssessment(
      injuryType: InjuryType.plantarFasciitis,
      riskScore: riskScore,
      riskLevel: _getRiskLevel(riskScore),
      timeToOnset: _estimateTimeToOnset(riskScore),
      riskFactors: riskFactors,
      preventionActions: _getPlantarFasciitisPreventionActions(riskScore),
    );
  }

  // Runner's Knee Prediction
  Future<InjuryRiskAssessment> predictRunnersKneeRisk({
    required String userId,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? activityData,
    Map<String, dynamic>? aisriData,
  }) async {
    double riskScore = 0.0;
    final riskFactors = <String>[];

    // High vertical oscillation
    final vo = activityData?['avg_vertical_oscillation'] ?? 8.0;
    if (vo > 10.0) {
      riskScore += 25;
      riskFactors.add('High vertical oscillation (${vo.toStringAsFixed(1)}cm)');
    } else if (vo > 9.0) {
      riskScore += 15;
      riskFactors
          .add('Elevated vertical oscillation (${vo.toStringAsFixed(1)}cm)');
    }

    // AISRI quad weakness
    if (aisriData?['quad_weakness'] == true) {
      riskScore += 25;
      riskFactors.add('Quadriceps weakness');
    }

    // Hip instability
    if (aisriData?['hip_instability'] == true) {
      riskScore += 20;
      riskFactors.add('Hip instability detected');
    }

    // Rapid mileage increase
    final weeklyIncrease = activityData?['weekly_mileage_increase'] ?? 0.0;
    if (weeklyIncrease > 0.10) {
      riskScore += 20;
      riskFactors.add('Rapid training increase');
    }

    // Previous knee issues
    if (aisriData?['history_knee_pain'] == true) {
      riskScore += 15;
      riskFactors.add('Previous knee issues');
    }

    riskScore = riskScore.clamp(0, 100);

    return InjuryRiskAssessment(
      injuryType: InjuryType.runnersKnee,
      riskScore: riskScore,
      riskLevel: _getRiskLevel(riskScore),
      timeToOnset: _estimateTimeToOnset(riskScore),
      riskFactors: riskFactors,
      preventionActions: _getRunnersKneePreventionActions(riskScore),
    );
  }

  // Achilles Tendinopathy Prediction
  Future<InjuryRiskAssessment> predictAchillesTendinopathyRisk({
    required String userId,
    Map<String, dynamic>? userData,
    Map<String, dynamic>? activityData,
    Map<String, dynamic>? aisriData,
  }) async {
    double riskScore = 0.0;
    final riskFactors = <String>[];

    // AISRI calf flexibility
    if (aisriData?['limited_calf_flexibility'] == true) {
      riskScore += 25;
      riskFactors.add('Limited calf flexibility');
    }

    // Rapid training ramp
    final weeklyIncrease = activityData?['weekly_mileage_increase'] ?? 0.0;
    if (weeklyIncrease > 0.15) {
      riskScore += 30;
      riskFactors.add('Very rapid training increase');
    } else if (weeklyIncrease > 0.10) {
      riskScore += 20;
      riskFactors.add('Rapid training increase');
    }

    // High intensity/speed work
    final speedWorkPercentage = activityData?['speed_work_percentage'] ?? 0.0;
    if (speedWorkPercentage > 0.25) {
      riskScore += 20;
      riskFactors.add('High volume of speed work');
    }

    // Hill running
    final hillPercentage = activityData?['hill_percentage'] ?? 0.0;
    if (hillPercentage > 0.30) {
      riskScore += 15;
      riskFactors.add('Frequent hill running');
    }

    // Previous Achilles issues
    if (aisriData?['history_achilles'] == true) {
      riskScore += 25;
      riskFactors.add('Previous Achilles injury');
    }

    riskScore = riskScore.clamp(0, 100);

    return InjuryRiskAssessment(
      injuryType: InjuryType.achillesTendinopathy,
      riskScore: riskScore,
      riskLevel: _getRiskLevel(riskScore),
      timeToOnset: _estimateTimeToOnset(riskScore),
      riskFactors: riskFactors,
      preventionActions: _getAchillesPreventionActions(riskScore),
    );
  }

  // Helper: Get risk level from score
  RiskLevel _getRiskLevel(double score) {
    if (score < 31) return RiskLevel.low;
    if (score < 61) return RiskLevel.moderate;
    if (score < 81) return RiskLevel.high;
    return RiskLevel.veryHigh;
  }

  // Helper: Estimate time to onset
  String _estimateTimeToOnset(double score) {
    if (score < 31) return '3+ months (low risk)';
    if (score < 61) return '1-3 months';
    if (score < 81) return '2-4 weeks';
    return '7-14 days';
  }

  // Prevention actions for IT Band
  List<String> _getITBandPreventionActions(double score) {
    final actions = <String>[
      'Hip strengthening exercises 3x/week (clamshells, side leg raises)',
      'Foam roll IT band and hip flexors daily',
      'Increase cadence gradually to 170-180 spm',
    ];

    if (score > 60) {
      actions.addAll([
        'Reduce weekly mileage by 20%',
        'Limit hill running to <20% of weekly volume',
        'Add 2 rest days per week',
        'Consider physical therapy evaluation',
      ]);
    } else if (score > 30) {
      actions.addAll([
        'Reduce weekly mileage by 10%',
        'Add 1 extra rest day per week',
      ]);
    }

    return actions;
  }

  // Prevention actions for Shin Splints
  List<String> _getShinSplintsPreventionActions(double score) {
    final actions = <String>[
      'Calf strengthening (heel raises, toe walks)',
      'Improve cadence to 170-180 spm',
      'Run on softer surfaces (grass, trails)',
      'Check shoe cushioning and replace if needed',
    ];

    if (score > 60) {
      actions.addAll([
        'Reduce training volume by 30%',
        'Ice shins after runs (15 minutes)',
        'Consider 7-14 day running break',
        'Cross-train with swimming or cycling',
      ]);
    }

    return actions;
  }

  // Prevention actions for Plantar Fasciitis
  List<String> _getPlantarFasciitisPreventionActions(double score) {
    final actions = <String>[
      'Daily calf and plantar fascia stretching',
      'Roll foot on frozen water bottle',
      'Wear supportive shoes with good arch support',
      'Reduce stride length - increase cadence',
    ];

    if (score > 60) {
      actions.addAll([
        'Reduce weekly mileage by 25%',
        'Limit speed work and hills',
        'Consider custom orthotics',
        'Night splints may help',
      ]);
    }

    return actions;
  }

  // Prevention actions for Runner's Knee
  List<String> _getRunnersKneePreventionActions(double score) {
    final actions = <String>[
      'Quad strengthening (squats, lunges, leg extensions)',
      'Hip stability exercises (single-leg balance, hip hikes)',
      'Reduce vertical bounce - run smoother',
      'Focus on knee alignment during exercises',
    ];

    if (score > 60) {
      actions.addAll([
        'Reduce training volume by 20%',
        'Avoid hills and stairs temporarily',
        'Ice knee after runs',
        'Consider physical therapy',
      ]);
    }

    return actions;
  }

  // Prevention actions for Achilles
  List<String> _getAchillesPreventionActions(double score) {
    final actions = <String>[
      'Daily calf stretching (straight and bent knee)',
      'Eccentric heel drops 3x15 reps, 2x/day',
      'Reduce heel drop in shoes gradually',
      'Warm up calves thoroughly before runs',
    ];

    if (score > 60) {
      actions.addAll([
        'Reduce training volume by 30%',
        'Eliminate speed work and hills for 2 weeks',
        'Consider complete rest if pain present',
        'Seek medical evaluation if symptoms persist',
      ]);
    }

    return actions;
  }

  // Helper: Get user data
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();
      return response;
    } catch (e) {
      developer.log('❌ Error getting user data: $e');
      return {};
    }
  }

  // Helper: Get recent activity data
  Future<Map<String, dynamic>> _getRecentActivityData(String userId,
      {int days = 28}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final activities = await _supabase
          .from('gps_activities')
          .select()
          .eq('user_id', userId)
          .gte('start_time', startDate.toIso8601String());

      if (activities.isEmpty) {
        return {
          'weekly_mileage': 0,
          'weekly_mileage_increase': 0.0,
          'avg_cadence': 175.0,
          'rest_days_per_week': 2,
        };
      }

      // Calculate metrics
      final totalDistance = (activities as List)
          .fold<double>(0, (sum, act) => sum + (act['distance_km'] ?? 0));

      final avgCadence = activities.isEmpty
          ? 175.0
          : activities.fold<double>(
                  0, (sum, act) => sum + (act['avg_cadence'] ?? 175)) /
              activities.length;

      // Calculate weekly mileage increase
      final last7Days = activities
          .where((act) => DateTime.parse(act['start_time'])
              .isAfter(DateTime.now().subtract(const Duration(days: 7))))
          .toList();
      final prev7Days = activities
          .where((act) =>
              DateTime.parse(act['start_time'])
                  .isBefore(DateTime.now().subtract(const Duration(days: 7))) &&
              DateTime.parse(act['start_time'])
                  .isAfter(DateTime.now().subtract(const Duration(days: 14))))
          .toList();

      final last7Mileage = last7Days.fold<double>(
          0, (sum, act) => sum + (act['distance_km'] ?? 0));
      final prev7Mileage = prev7Days.fold<double>(
          0, (sum, act) => sum + (act['distance_km'] ?? 0));

      final mileageIncrease =
          prev7Mileage > 0 ? (last7Mileage - prev7Mileage) / prev7Mileage : 0.0;

      return {
        'weekly_mileage': last7Mileage,
        'weekly_mileage_increase': mileageIncrease,
        'avg_cadence': avgCadence,
        'total_distance': totalDistance,
        'activity_count': activities.length,
        'rest_days_per_week': 7 - (last7Days.length),
      };
    } catch (e) {
      developer.log('❌ Error getting activity data: $e');
      return {};
    }
  }

  // Helper: Get latest AISRI data
  Future<Map<String, dynamic>> _getLatestAISRIData(String userId) async {
    try {
      final response = await _supabase
          .from('aisri_assessments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      developer.log('❌ Error getting AISRI data: $e');
      return {};
    }
  }

  // Helper: Save predictions to database
  Future<void> _savePredictions(
      String userId, List<InjuryRiskAssessment> predictions) async {
    try {
      // Note: This requires an injury_predictions table
      // For now, just log the predictions
      // final data = predictions.map((p) => {
      //   'user_id': userId,
      //   'injury_type': p.injuryType.name,
      //   'risk_score': p.riskScore,
      //   'risk_level': p.riskLevel.name,
      //   'time_to_onset': p.timeToOnset,
      //   'risk_factors': p.riskFactors,
      //   'prevention_actions': p.preventionActions,
      //   'predicted_at': DateTime.now().toIso8601String(),
      // });
      developer.log('✅ Injury predictions generated: ${predictions.length}');
      for (final p in predictions) {
        developer.log(
            '  ${p.injuryName}: ${p.riskScore.toStringAsFixed(0)}% (${p.riskLevel.name})');
      }
    } catch (e) {
      developer.log('❌ Error saving predictions: $e');
    }
  }
}
