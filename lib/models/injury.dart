// lib/models/injury.dart

class Injury {
  final String id;
  final String userId;
  
  // Injury Details
  final String injuryName;
  final String injuryType;
  final String affectedArea;
  
  // Severity & Status
  final int severity;
  final int? currentPainLevel;
  final String status;
  
  // Timeline
  final DateTime injuryDate;
  final DateTime? diagnosedDate;
  final DateTime? expectedRecoveryDate;
  final DateTime? actualRecoveryDate;
  
  // Cause & Context
  final String? causedBy;
  final String? relatedWorkoutId;
  final List<String>? contributingFactors;
  
  // Treatment
  final String? treatmentPlan;
  final List<String>? medications;
  final bool physicalTherapy;
  final int? restDays;
  final bool crossTrainingAllowed;
  
  // Medical
  final String? diagnosedBy;
  final String? diagnosisNotes;
  final String? medicalImaging;
  final String? imagingResults;
  
  // Recovery Progress
  final int recoveryPercentage;
  final String? recoveryNotes;
  
  // Prevention
  final List<String>? preventionRecommendations;
  final List<String>? correctiveExercises;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  Injury({
    required this.id,
    required this.userId,
    required this.injuryName,
    required this.injuryType,
    required this.affectedArea,
    required this.severity,
    this.currentPainLevel,
    required this.status,
    required this.injuryDate,
    this.diagnosedDate,
    this.expectedRecoveryDate,
    this.actualRecoveryDate,
    this.causedBy,
    this.relatedWorkoutId,
    this.contributingFactors,
    this.treatmentPlan,
    this.medications,
    this.physicalTherapy = false,
    this.restDays,
    this.crossTrainingAllowed = false,
    this.diagnosedBy,
    this.diagnosisNotes,
    this.medicalImaging,
    this.imagingResults,
    this.recoveryPercentage = 0,
    this.recoveryNotes,
    this.preventionRecommendations,
    this.correctiveExercises,
    required this.createdAt,
    this.updatedAt,
  });

  // Helper getters
  int get daysSinceInjury {
    final endDate = actualRecoveryDate ?? DateTime.now();
    return endDate.difference(injuryDate).inDays;
  }

  int? get daysUntilRecovery {
    if (expectedRecoveryDate == null) return null;
    if (status == 'healed') return 0;
    final days = expectedRecoveryDate!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }

  String get affectedAreaDisplay {
    return affectedArea
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String get injuryTypeDisplay {
    return injuryType[0].toUpperCase() + injuryType.substring(1);
  }

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'recovering':
        return 'Recovering';
      case 'healed':
        return 'Healed';
      case 'chronic':
        return 'Chronic';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'active':
        return '#F44336';
      case 'recovering':
        return '#FF9800';
      case 'healed':
        return '#4CAF50';
      case 'chronic':
        return '#9C27B0';
      default:
        return '#9E9E9E';
    }
  }

  String get severityLabel {
    if (severity >= 8) return 'Severe';
    if (severity >= 5) return 'Moderate';
    return 'Mild';
  }

  String get severityColor {
    if (severity >= 8) return '#F44336';
    if (severity >= 5) return '#FF9800';
    return '#FFC107';
  }

  bool get isActive => status == 'active' || status == 'recovering';
  bool get requiresMedicalAttention => severity >= 7 || medicalImaging != null;

  // Supabase JSON serialization
  factory Injury.fromJson(Map<String, dynamic> json) {
    return Injury(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      injuryName: json['injury_name'] as String,
      injuryType: json['injury_type'] as String,
      affectedArea: json['affected_area'] as String,
      severity: json['severity'] as int,
      currentPainLevel: json['current_pain_level'] as int?,
      status: json['status'] as String,
      injuryDate: DateTime.parse(json['injury_date'] as String),
      diagnosedDate: json['diagnosed_date'] != null
          ? DateTime.parse(json['diagnosed_date'] as String)
          : null,
      expectedRecoveryDate: json['expected_recovery_date'] != null
          ? DateTime.parse(json['expected_recovery_date'] as String)
          : null,
      actualRecoveryDate: json['actual_recovery_date'] != null
          ? DateTime.parse(json['actual_recovery_date'] as String)
          : null,
      causedBy: json['caused_by'] as String?,
      relatedWorkoutId: json['related_workout_id'] as String?,
      contributingFactors: (json['contributing_factors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      treatmentPlan: json['treatment_plan'] as String?,
      medications: (json['medications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      physicalTherapy: json['physical_therapy'] as bool? ?? false,
      restDays: json['rest_days'] as int?,
      crossTrainingAllowed: json['cross_training_allowed'] as bool? ?? false,
      diagnosedBy: json['diagnosed_by'] as String?,
      diagnosisNotes: json['diagnosis_notes'] as String?,
      medicalImaging: json['medical_imaging'] as String?,
      imagingResults: json['imaging_results'] as String?,
      recoveryPercentage: json['recovery_percentage'] as int? ?? 0,
      recoveryNotes: json['recovery_notes'] as String?,
      preventionRecommendations: (json['prevention_recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      correctiveExercises: (json['corrective_exercises'] as List<dynamic>?)
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
      'injury_name': injuryName,
      'injury_type': injuryType,
      'affected_area': affectedArea,
      'severity': severity,
      'current_pain_level': currentPainLevel,
      'status': status,
      'injury_date': injuryDate.toIso8601String().split('T')[0],
      'diagnosed_date': diagnosedDate?.toIso8601String().split('T')[0],
      'expected_recovery_date': expectedRecoveryDate?.toIso8601String().split('T')[0],
      'actual_recovery_date': actualRecoveryDate?.toIso8601String().split('T')[0],
      'caused_by': causedBy,
      'related_workout_id': relatedWorkoutId,
      'contributing_factors': contributingFactors,
      'treatment_plan': treatmentPlan,
      'medications': medications,
      'physical_therapy': physicalTherapy,
      'rest_days': restDays,
      'cross_training_allowed': crossTrainingAllowed,
      'diagnosed_by': diagnosedBy,
      'diagnosis_notes': diagnosisNotes,
      'medical_imaging': medicalImaging,
      'imaging_results': imagingResults,
      'recovery_percentage': recoveryPercentage,
      'recovery_notes': recoveryNotes,
      'prevention_recommendations': preventionRecommendations,
      'corrective_exercises': correctiveExercises,
    };
  }

  Injury copyWith({
    int? currentPainLevel,
    String? status,
    DateTime? expectedRecoveryDate,
    DateTime? actualRecoveryDate,
    String? treatmentPlan,
    int? recoveryPercentage,
    String? recoveryNotes,
  }) {
    return Injury(
      id: id,
      userId: userId,
      injuryName: injuryName,
      injuryType: injuryType,
      affectedArea: affectedArea,
      severity: severity,
      currentPainLevel: currentPainLevel ?? this.currentPainLevel,
      status: status ?? this.status,
      injuryDate: injuryDate,
      diagnosedDate: diagnosedDate,
      expectedRecoveryDate: expectedRecoveryDate ?? this.expectedRecoveryDate,
      actualRecoveryDate: actualRecoveryDate ?? this.actualRecoveryDate,
      causedBy: causedBy,
      relatedWorkoutId: relatedWorkoutId,
      contributingFactors: contributingFactors,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      medications: medications,
      physicalTherapy: physicalTherapy,
      restDays: restDays,
      crossTrainingAllowed: crossTrainingAllowed,
      diagnosedBy: diagnosedBy,
      diagnosisNotes: diagnosisNotes,
      medicalImaging: medicalImaging,
      imagingResults: imagingResults,
      recoveryPercentage: recoveryPercentage ?? this.recoveryPercentage,
      recoveryNotes: recoveryNotes ?? this.recoveryNotes,
      preventionRecommendations: preventionRecommendations,
      correctiveExercises: correctiveExercises,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
