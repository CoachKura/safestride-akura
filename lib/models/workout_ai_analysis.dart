// lib/models/workout_ai_analysis.dart

class WorkoutAIAnalysis {
  final String id;
  final String userId;
  
  // Analysis Metadata
  final DateTime analysisDate;
  final String analysisVersion;
  final String dataSource;
  
  // Analysis Period
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final int totalWorkoutsAnalyzed;
  final double? totalDistanceKm;
  final double? totalDurationHours;
  
  // Overall Injury Prevention Score (0-100)
  final int injuryPreventionScore;
  final String riskLevel;
  final String riskCategoryColor;
  
  // Issue Counts
  final int criticalIssuesCount;
  final int warningIssuesCount;
  final int infoIssuesCount;
  final int strengthsCount;
  
  // Detailed Issues (JSONB)
  final List<Map<String, dynamic>> criticalIssues;
  final List<Map<String, dynamic>> warningIssues;
  final List<Map<String, dynamic>> infoIssues;
  final List<Map<String, dynamic>> strengths;
  
  // Key Metrics Analysis
  final int? avgCadenceSpm;
  final String? targetCadenceSpm;
  final String? cadenceStatus;
  
  final double? avgVerticalOscillationCm;
  final String? targetVerticalOscillationCm;
  final String? verticalOscillationStatus;
  
  final int? avgGroundContactTimeMs;
  final String? targetGroundContactTimeMs;
  final String? groundContactTimeStatus;
  
  final int? avgHeartRateBpm;
  final int? maxHeartRateBpm;
  final Map<String, dynamic>? hrZoneDistribution;
  
  final double? weeklyDistanceKm;
  final double? weeklyDistanceChangePercentage;
  final String? distanceChangeStatus;
  
  // Training Load
  final int? trainingLoadScore;
  final int? trainingStressBalance;
  final double? acuteChronicWorkloadRatio;
  final String? acwrStatus;
  
  // Recovery Analysis
  final int? restDaysInPeriod;
  final String? recoveryAdequacy;
  final List<String>? fatigueIndicators;
  
  // AI Recommendations
  final List<String> topRecommendations;
  final List<String>? protocolFocusAreas;
  
  // Generated Protocol
  final String? generatedProtocolId;
  final bool protocolGenerated;
  final DateTime? protocolGenerationDate;
  
  // Comparison with Previous Analysis
  final String? previousAnalysisId;
  final int? scoreChange;
  final List<String>? improvementsNoted;
  final List<String>? regressionsNoted;
  
  // Raw Data Reference
  final List<String>? workoutIds;
  
  // User Feedback
  final int? userRating;
  final String? userFeedback;
  final List<String>? recommendationsFollowed;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkoutAIAnalysis({
    required this.id,
    required this.userId,
    required this.analysisDate,
    this.analysisVersion = '1.0',
    required this.dataSource,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.totalWorkoutsAnalyzed,
    this.totalDistanceKm,
    this.totalDurationHours,
    required this.injuryPreventionScore,
    required this.riskLevel,
    required this.riskCategoryColor,
    this.criticalIssuesCount = 0,
    this.warningIssuesCount = 0,
    this.infoIssuesCount = 0,
    this.strengthsCount = 0,
    this.criticalIssues = const [],
    this.warningIssues = const [],
    this.infoIssues = const [],
    this.strengths = const [],
    this.avgCadenceSpm,
    this.targetCadenceSpm,
    this.cadenceStatus,
    this.avgVerticalOscillationCm,
    this.targetVerticalOscillationCm,
    this.verticalOscillationStatus,
    this.avgGroundContactTimeMs,
    this.targetGroundContactTimeMs,
    this.groundContactTimeStatus,
    this.avgHeartRateBpm,
    this.maxHeartRateBpm,
    this.hrZoneDistribution,
    this.weeklyDistanceKm,
    this.weeklyDistanceChangePercentage,
    this.distanceChangeStatus,
    this.trainingLoadScore,
    this.trainingStressBalance,
    this.acuteChronicWorkloadRatio,
    this.acwrStatus,
    this.restDaysInPeriod,
    this.recoveryAdequacy,
    this.fatigueIndicators,
    this.topRecommendations = const [],
    this.protocolFocusAreas,
    this.generatedProtocolId,
    this.protocolGenerated = false,
    this.protocolGenerationDate,
    this.previousAnalysisId,
    this.scoreChange,
    this.improvementsNoted,
    this.regressionsNoted,
    this.workoutIds,
    this.userRating,
    this.userFeedback,
    this.recommendationsFollowed,
    required this.createdAt,
    this.updatedAt,
  });

  // Helper getters
  String get riskLevelDisplay {
    switch (riskLevel) {
      case 'low':
        return 'Low Risk';
      case 'moderate':
        return 'Moderate Risk';
      case 'high':
        return 'High Risk';
      case 'critical':
        return 'Critical Risk';
      default:
        return riskLevel;
    }
  }

  bool get hasCriticalIssues => criticalIssuesCount > 0;
  bool get hasWarnings => warningIssuesCount > 0;
  bool get hasRecommendations => topRecommendations.isNotEmpty;
  
  int get totalIssuesCount =>
    criticalIssuesCount + warningIssuesCount + infoIssuesCount;

  String get scoreGrade {
    if (injuryPreventionScore >= 90) return 'A+';
    if (injuryPreventionScore >= 80) return 'A';
    if (injuryPreventionScore >= 70) return 'B';
    if (injuryPreventionScore >= 60) return 'C';
    if (injuryPreventionScore >= 50) return 'D';
    return 'F';
  }

  bool get isImproving => scoreChange != null && scoreChange! > 0;
  bool get isRegressing => scoreChange != null && scoreChange! < 0;

  String get cadenceStatusDisplay {
    switch (cadenceStatus) {
      case 'optimal':
        return '✓ Optimal';
      case 'low':
        return '⚠ Low';
      case 'high':
        return '⚠ High';
      case 'needs_improvement':
        return '⚠ Needs Improvement';
      default:
        return cadenceStatus ?? 'Unknown';
    }
  }

  String get recoveryAdequacyDisplay {
    switch (recoveryAdequacy) {
      case 'sufficient':
        return '✓ Sufficient';
      case 'borderline':
        return '⚠ Borderline';
      case 'insufficient':
        return '⚠ Insufficient';
      default:
        return recoveryAdequacy ?? 'Unknown';
    }
  }

  int get periodDays => periodEndDate.difference(periodStartDate).inDays + 1;

  // Supabase JSON serialization
  factory WorkoutAIAnalysis.fromJson(Map<String, dynamic> json) {
    return WorkoutAIAnalysis(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      analysisDate: DateTime.parse(json['analysis_date'] as String),
      analysisVersion: json['analysis_version'] as String? ?? '1.0',
      dataSource: json['data_source'] as String,
      periodStartDate: DateTime.parse(json['period_start_date'] as String),
      periodEndDate: DateTime.parse(json['period_end_date'] as String),
      totalWorkoutsAnalyzed: json['total_workouts_analyzed'] as int,
      totalDistanceKm: json['total_distance_km'] != null
          ? (json['total_distance_km'] as num).toDouble()
          : null,
      totalDurationHours: json['total_duration_hours'] != null
          ? (json['total_duration_hours'] as num).toDouble()
          : null,
      injuryPreventionScore: json['injury_prevention_score'] as int,
      riskLevel: json['risk_level'] as String,
      riskCategoryColor: json['risk_category_color'] as String,
      criticalIssuesCount: json['critical_issues_count'] as int? ?? 0,
      warningIssuesCount: json['warning_issues_count'] as int? ?? 0,
      infoIssuesCount: json['info_issues_count'] as int? ?? 0,
      strengthsCount: json['strengths_count'] as int? ?? 0,
      criticalIssues: (json['critical_issues'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      warningIssues: (json['warning_issues'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      infoIssues: (json['info_issues'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      strengths: (json['strengths'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      avgCadenceSpm: json['avg_cadence_spm'] as int?,
      targetCadenceSpm: json['target_cadence_spm'] as String?,
      cadenceStatus: json['cadence_status'] as String?,
      avgVerticalOscillationCm: json['avg_vertical_oscillation_cm'] != null
          ? (json['avg_vertical_oscillation_cm'] as num).toDouble()
          : null,
      targetVerticalOscillationCm: json['target_vertical_oscillation_cm'] as String?,
      verticalOscillationStatus: json['vertical_oscillation_status'] as String?,
      avgGroundContactTimeMs: json['avg_ground_contact_time_ms'] as int?,
      targetGroundContactTimeMs: json['target_ground_contact_time_ms'] as String?,
      groundContactTimeStatus: json['ground_contact_time_status'] as String?,
      avgHeartRateBpm: json['avg_heart_rate_bpm'] as int?,
      maxHeartRateBpm: json['max_heart_rate_bpm'] as int?,
      hrZoneDistribution: json['hr_zone_distribution'] as Map<String, dynamic>?,
      weeklyDistanceKm: json['weekly_distance_km'] != null
          ? (json['weekly_distance_km'] as num).toDouble()
          : null,
      weeklyDistanceChangePercentage: json['weekly_distance_change_percentage'] != null
          ? (json['weekly_distance_change_percentage'] as num).toDouble()
          : null,
      distanceChangeStatus: json['distance_change_status'] as String?,
      trainingLoadScore: json['training_load_score'] as int?,
      trainingStressBalance: json['training_stress_balance'] as int?,
      acuteChronicWorkloadRatio: json['acute_chronic_workload_ratio'] != null
          ? (json['acute_chronic_workload_ratio'] as num).toDouble()
          : null,
      acwrStatus: json['acwr_status'] as String?,
      restDaysInPeriod: json['rest_days_in_period'] as int?,
      recoveryAdequacy: json['recovery_adequacy'] as String?,
      fatigueIndicators: (json['fatigue_indicators'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      topRecommendations: (json['top_recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      protocolFocusAreas: (json['protocol_focus_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      generatedProtocolId: json['generated_protocol_id'] as String?,
      protocolGenerated: json['protocol_generated'] as bool? ?? false,
      protocolGenerationDate: json['protocol_generation_date'] != null
          ? DateTime.parse(json['protocol_generation_date'] as String)
          : null,
      previousAnalysisId: json['previous_analysis_id'] as String?,
      scoreChange: json['score_change'] as int?,
      improvementsNoted: (json['improvements_noted'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      regressionsNoted: (json['regressions_noted'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      workoutIds: (json['workout_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      userRating: json['user_rating'] as int?,
      userFeedback: json['user_feedback'] as String?,
      recommendationsFollowed: (json['recommendations_followed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'analysis_date': analysisDate.toIso8601String(),
      'analysis_version': analysisVersion,
      'data_source': dataSource,
      'period_start_date': periodStartDate.toIso8601String().split('T')[0],
      'period_end_date': periodEndDate.toIso8601String().split('T')[0],
      'total_workouts_analyzed': totalWorkoutsAnalyzed,
      'total_distance_km': totalDistanceKm,
      'total_duration_hours': totalDurationHours,
      'injury_prevention_score': injuryPreventionScore,
      'risk_level': riskLevel,
      'critical_issues': criticalIssues,
      'warning_issues': warningIssues,
      'info_issues': infoIssues,
      'strengths': strengths,
      'avg_cadence_spm': avgCadenceSpm,
      'target_cadence_spm': targetCadenceSpm,
      'cadence_status': cadenceStatus,
      'avg_vertical_oscillation_cm': avgVerticalOscillationCm,
      'target_vertical_oscillation_cm': targetVerticalOscillationCm,
      'vertical_oscillation_status': verticalOscillationStatus,
      'avg_ground_contact_time_ms': avgGroundContactTimeMs,
      'target_ground_contact_time_ms': targetGroundContactTimeMs,
      'ground_contact_time_status': groundContactTimeStatus,
      'avg_heart_rate_bpm': avgHeartRateBpm,
      'max_heart_rate_bpm': maxHeartRateBpm,
      'hr_zone_distribution': hrZoneDistribution,
      'weekly_distance_km': weeklyDistanceKm,
      'weekly_distance_change_percentage': weeklyDistanceChangePercentage,
      'distance_change_status': distanceChangeStatus,
      'training_load_score': trainingLoadScore,
      'training_stress_balance': trainingStressBalance,
      'acute_chronic_workload_ratio': acuteChronicWorkloadRatio,
      'acwr_status': acwrStatus,
      'rest_days_in_period': restDaysInPeriod,
      'recovery_adequacy': recoveryAdequacy,
      'fatigue_indicators': fatigueIndicators,
      'top_recommendations': topRecommendations,
      'protocol_focus_areas': protocolFocusAreas,
      'generated_protocol_id': generatedProtocolId,
      'protocol_generated': protocolGenerated,
      'protocol_generation_date': protocolGenerationDate?.toIso8601String(),
      'previous_analysis_id': previousAnalysisId,
      'score_change': scoreChange,
      'improvements_noted': improvementsNoted,
      'regressions_noted': regressionsNoted,
      'workout_ids': workoutIds,
      'user_rating': userRating,
      'user_feedback': userFeedback,
      'recommendations_followed': recommendationsFollowed,
    };
  }
}
