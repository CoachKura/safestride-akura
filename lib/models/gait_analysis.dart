// lib/models/gait_analysis.dart

class GaitAnalysis {
  final String id;
  final String userId;
  final String? assessmentId;
  
  // Analysis Metadata
  final DateTime analysisDate;
  final String analysisVersion;
  
  // Pathology Detection (Confidence Scores 0-100)
  final int? bowLegsConfidence;
  final int? knockKneesConfidence;
  final int? overpronationConfidence;
  final int? underpronationConfidence;
  
  // Detected Pathologies
  final List<String> detectedPathologies;
  final String? primaryPathology;
  
  // Biomechanical Analysis
  final Map<String, dynamic>? forceVectorAnalysis;
  final Map<String, dynamic>? muscleActivationPatterns;
  final double? energyCostPercentage;
  
  // Injury Risk Assessment
  final String? injuryRiskLevel;
  final int? injuryRiskScore;
  final List<String>? specificInjuryRisks;
  final Map<String, dynamic>? riskPercentages;
  
  // Corrective Recommendations
  final Map<String, dynamic>? correctiveExercises;
  final List<String>? footwearRecommendations;
  final List<String>? terrainModifications;
  final List<String>? trainingAdjustments;
  
  // Progress Tracking
  final String? previousAnalysisId;
  final String? improvementNotes;
  
  // Raw Assessment Data
  final double? ankleMobilityLeft;
  final double? ankleMobilityRight;
  final int? hipAbductionReps;
  final double? singleLegBalanceSeconds;
  final double? kneeValgusAngle;
  final double? qAngle;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  GaitAnalysis({
    required this.id,
    required this.userId,
    this.assessmentId,
    required this.analysisDate,
    this.analysisVersion = '1.0',
    this.bowLegsConfidence,
    this.knockKneesConfidence,
    this.overpronationConfidence,
    this.underpronationConfidence,
    this.detectedPathologies = const [],
    this.primaryPathology,
    this.forceVectorAnalysis,
    this.muscleActivationPatterns,
    this.energyCostPercentage,
    this.injuryRiskLevel,
    this.injuryRiskScore,
    this.specificInjuryRisks,
    this.riskPercentages,
    this.correctiveExercises,
    this.footwearRecommendations,
    this.terrainModifications,
    this.trainingAdjustments,
    this.previousAnalysisId,
    this.improvementNotes,
    this.ankleMobilityLeft,
    this.ankleMobilityRight,
    this.hipAbductionReps,
    this.singleLegBalanceSeconds,
    this.kneeValgusAngle,
    this.qAngle,
    required this.createdAt,
    this.updatedAt,
  });

  // Helper getters
  bool get hasPathologies => detectedPathologies.isNotEmpty;
  
  String get primaryPathologyDisplay {
    if (primaryPathology == null) return 'None detected';
    return primaryPathology!
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String get injuryRiskLevelDisplay {
    if (injuryRiskLevel == null) return 'Unknown';
    switch (injuryRiskLevel) {
      case 'low':
        return 'Low Risk';
      case 'moderate':
        return 'Moderate Risk';
      case 'high':
        return 'High Risk';
      case 'critical':
        return 'Critical Risk';
      default:
        return injuryRiskLevel!;
    }
  }

  String get riskLevelColor {
    switch (injuryRiskLevel) {
      case 'low':
        return '#4CAF50';
      case 'moderate':
        return '#FFC107';
      case 'high':
        return '#FF9800';
      case 'critical':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  int get highestConfidence {
    final confidences = [
      bowLegsConfidence ?? 0,
      knockKneesConfidence ?? 0,
      overpronationConfidence ?? 0,
      underpronationConfidence ?? 0,
    ];
    return confidences.reduce((a, b) => a > b ? a : b);
  }

  bool get hasCorrectiveExercises => 
    correctiveExercises != null && correctiveExercises!.isNotEmpty;

  bool get hasFootwearRecommendations =>
    footwearRecommendations != null && footwearRecommendations!.isNotEmpty;

  // Supabase JSON serialization
  factory GaitAnalysis.fromJson(Map<String, dynamic> json) {
    return GaitAnalysis(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assessmentId: json['assessment_id'] as String?,
      analysisDate: DateTime.parse(json['analysis_date'] as String),
      analysisVersion: json['analysis_version'] as String? ?? '1.0',
      bowLegsConfidence: json['bow_legs_confidence'] as int?,
      knockKneesConfidence: json['knock_knees_confidence'] as int?,
      overpronationConfidence: json['overpronation_confidence'] as int?,
      underpronationConfidence: json['underpronation_confidence'] as int?,
      detectedPathologies: (json['detected_pathologies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      primaryPathology: json['primary_pathology'] as String?,
      forceVectorAnalysis: json['force_vector_analysis'] as Map<String, dynamic>?,
      muscleActivationPatterns: json['muscle_activation_patterns'] as Map<String, dynamic>?,
      energyCostPercentage: json['energy_cost_percentage'] != null
          ? (json['energy_cost_percentage'] as num).toDouble()
          : null,
      injuryRiskLevel: json['injury_risk_level'] as String?,
      injuryRiskScore: json['injury_risk_score'] as int?,
      specificInjuryRisks: (json['specific_injury_risks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      riskPercentages: json['risk_percentages'] as Map<String, dynamic>?,
      correctiveExercises: json['corrective_exercises'] as Map<String, dynamic>?,
      footwearRecommendations: (json['footwear_recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      terrainModifications: (json['terrain_modifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      trainingAdjustments: (json['training_adjustments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      previousAnalysisId: json['previous_analysis_id'] as String?,
      improvementNotes: json['improvement_notes'] as String?,
      ankleMobilityLeft: json['ankle_mobility_left'] != null
          ? (json['ankle_mobility_left'] as num).toDouble()
          : null,
      ankleMobilityRight: json['ankle_mobility_right'] != null
          ? (json['ankle_mobility_right'] as num).toDouble()
          : null,
      hipAbductionReps: json['hip_abduction_reps'] as int?,
      singleLegBalanceSeconds: json['single_leg_balance_seconds'] != null
          ? (json['single_leg_balance_seconds'] as num).toDouble()
          : null,
      kneeValgusAngle: json['knee_valgus_angle'] != null
          ? (json['knee_valgus_angle'] as num).toDouble()
          : null,
      qAngle: json['q_angle'] != null
          ? (json['q_angle'] as num).toDouble()
          : null,
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
      'assessment_id': assessmentId,
      'analysis_date': analysisDate.toIso8601String(),
      'analysis_version': analysisVersion,
      'bow_legs_confidence': bowLegsConfidence,
      'knock_knees_confidence': knockKneesConfidence,
      'overpronation_confidence': overpronationConfidence,
      'underpronation_confidence': underpronationConfidence,
      'detected_pathologies': detectedPathologies,
      'primary_pathology': primaryPathology,
      'force_vector_analysis': forceVectorAnalysis,
      'muscle_activation_patterns': muscleActivationPatterns,
      'energy_cost_percentage': energyCostPercentage,
      'injury_risk_level': injuryRiskLevel,
      'injury_risk_score': injuryRiskScore,
      'specific_injury_risks': specificInjuryRisks,
      'risk_percentages': riskPercentages,
      'corrective_exercises': correctiveExercises,
      'footwear_recommendations': footwearRecommendations,
      'terrain_modifications': terrainModifications,
      'training_adjustments': trainingAdjustments,
      'previous_analysis_id': previousAnalysisId,
      'improvement_notes': improvementNotes,
      'ankle_mobility_left': ankleMobilityLeft,
      'ankle_mobility_right': ankleMobilityRight,
      'hip_abduction_reps': hipAbductionReps,
      'single_leg_balance_seconds': singleLegBalanceSeconds,
      'knee_valgus_angle': kneeValgusAngle,
      'q_angle': qAngle,
    };
  }
}
