// lib/models/aisri_assessment.dart

class AISRIAssessment {
  final String id;
  final String userId;
  final DateTime assessmentDate;

  // Physical assessment scores (0-100)
  final int mobilityScore;
  final int strengthScore;
  final int balanceScore;
  final int flexibilityScore;
  final int enduranceScore;
  final int powerScore;

  // Training data
  final double weeklyDistance; // in kilometers
  final int avgCadence; // steps per minute
  final double avgPace; // minutes per kilometer

  // Injury history
  final List<String> pastInjuries;

  // Biomechanics data (optional)
  final double? groundContactTime; // milliseconds
  final double? verticalOscillation; // centimeters
  final double? strideLength; // meters

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  AISRIAssessment({
    required this.id,
    required this.userId,
    required this.assessmentDate,
    required this.mobilityScore,
    required this.strengthScore,
    required this.balanceScore,
    required this.flexibilityScore,
    required this.enduranceScore,
    required this.powerScore,
    required this.weeklyDistance,
    required this.avgCadence,
    required this.avgPace,
    required this.pastInjuries,
    this.groundContactTime,
    this.verticalOscillation,
    this.strideLength,
    required this.createdAt,
    this.updatedAt,
  });

  // Computed AISRI Score (0-100)
  int get aisriScore {
    return _calculateAISRI(
      mobility: mobilityScore,
      strength: strengthScore,
      balance: balanceScore,
      flexibility: flexibilityScore,
      endurance: enduranceScore,
      power: powerScore,
      weeklyDistance: weeklyDistance,
      avgCadence: avgCadence,
      avgPace: avgPace,
      injuryCount: pastInjuries.length,
      groundContactTime: groundContactTime,
      verticalOscillation: verticalOscillation,
    );
  }

  // Risk level based on AISRI score
  String get riskLevel {
    if (aisriScore >= 80) return 'Low Risk';
    if (aisriScore >= 60) return 'Moderate Risk';
    if (aisriScore >= 40) return 'High Risk';
    return 'Very High Risk';
  }

  // Risk color for UI
  String get riskColor {
    if (aisriScore >= 80) return '#4CAF50'; // Green
    if (aisriScore >= 60) return '#FFC107'; // Amber
    if (aisriScore >= 40) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  // Proprietary AISRI calculation formula
  int _calculateAISRI({
    required int mobility,
    required int strength,
    required int balance,
    required int flexibility,
    required int endurance,
    required int power,
    required double weeklyDistance,
    required int avgCadence,
    required double avgPace,
    required int injuryCount,
    double? groundContactTime,
    double? verticalOscillation,
  }) {
    // Weighted physical assessment (50%)
    double physicalScore = (mobility * 0.20 +
        strength * 0.15 +
        balance * 0.20 +
        flexibility * 0.15 +
        endurance * 0.15 +
        power * 0.15);

    // Training load factor (20%)
    double trainingScore = _calculateTrainingScore(
      weeklyDistance,
      avgCadence,
      avgPace,
    );

    // Injury history penalty (15%)
    double injuryPenalty = _calculateInjuryPenalty(injuryCount);

    // Biomechanics bonus (15%)
    double biomechanicsBonus = _calculateBiomechanicsScore(
      groundContactTime,
      verticalOscillation,
    );

    // Calculate final score
    double finalScore = (physicalScore * 0.50 +
        trainingScore * 0.20 -
        injuryPenalty * 0.15 +
        biomechanicsBonus * 0.15);

    return finalScore.clamp(0, 100).round();
  }

  double _calculateTrainingScore(double distance, int cadence, double pace) {
    // Optimal weekly distance: 30-50km
    double distanceScore = distance >= 30 && distance <= 50
        ? 100
        : distance < 30
            ? (distance / 30) * 100
            : 100 - ((distance - 50) / 50 * 20);

    // Optimal cadence: 170-180 spm
    double cadenceScore = cadence >= 170 && cadence <= 180
        ? 100
        : 100 - ((cadence - 175).abs() * 2);

    // Optimal pace: 5-6 min/km
    double paceScore =
        pace >= 5 && pace <= 6 ? 100 : 100 - ((pace - 5.5).abs() * 10);

    return (distanceScore + cadenceScore + paceScore) / 3;
  }

  double _calculateInjuryPenalty(int count) {
    if (count == 0) return 0;
    if (count <= 2) return 20;
    if (count <= 4) return 40;
    return 60;
  }

  double _calculateBiomechanicsScore(double? gct, double? vo) {
    if (gct == null && vo == null) return 50; // Neutral if no data

    double score = 50;

    if (gct != null) {
      // Optimal ground contact time: 200-250ms
      if (gct >= 200 && gct <= 250) {
        score += 25;
      } else {
        score += 25 - ((gct - 225).abs() / 10);
      }
    }

    if (vo != null) {
      // Optimal vertical oscillation: 6-10cm
      if (vo >= 6 && vo <= 10) {
        score += 25;
      } else {
        score += 25 - ((vo - 8).abs() * 2);
      }
    }

    return score.clamp(0, 100);
  }

  // Supabase JSON serialization
  factory AISRIAssessment.fromJson(Map<String, dynamic> json) {
    return AISRIAssessment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assessmentDate: DateTime.parse(json['assessment_date'] as String),
      mobilityScore: json['mobility_score'] as int,
      strengthScore: json['strength_score'] as int,
      balanceScore: json['balance_score'] as int,
      flexibilityScore: json['flexibility_score'] as int,
      enduranceScore: json['endurance_score'] as int,
      powerScore: json['power_score'] as int,
      weeklyDistance: (json['weekly_distance'] as num).toDouble(),
      avgCadence: json['avg_cadence'] as int,
      avgPace: (json['avg_pace'] as num).toDouble(),
      pastInjuries: (json['past_injuries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      groundContactTime: json['ground_contact_time'] != null
          ? (json['ground_contact_time'] as num).toDouble()
          : null,
      verticalOscillation: json['vertical_oscillation'] != null
          ? (json['vertical_oscillation'] as num).toDouble()
          : null,
      strideLength: json['stride_length'] != null
          ? (json['stride_length'] as num).toDouble()
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
      'assessment_date': assessmentDate.toIso8601String(),
      'mobility_score': mobilityScore,
      'strength_score': strengthScore,
      'balance_score': balanceScore,
      'flexibility_score': flexibilityScore,
      'endurance_score': enduranceScore,
      'power_score': powerScore,
      'weekly_distance': weeklyDistance,
      'avg_cadence': avgCadence,
      'avg_pace': avgPace,
      'past_injuries': pastInjuries,
      'ground_contact_time': groundContactTime,
      'vertical_oscillation': verticalOscillation,
      'stride_length': strideLength,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  AISRIAssessment copyWith({
    String? id,
    String? userId,
    DateTime? assessmentDate,
    int? mobilityScore,
    int? strengthScore,
    int? balanceScore,
    int? flexibilityScore,
    int? enduranceScore,
    int? powerScore,
    double? weeklyDistance,
    int? avgCadence,
    double? avgPace,
    List<String>? pastInjuries,
    double? groundContactTime,
    double? verticalOscillation,
    double? strideLength,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AISRIAssessment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      mobilityScore: mobilityScore ?? this.mobilityScore,
      strengthScore: strengthScore ?? this.strengthScore,
      balanceScore: balanceScore ?? this.balanceScore,
      flexibilityScore: flexibilityScore ?? this.flexibilityScore,
      enduranceScore: enduranceScore ?? this.enduranceScore,
      powerScore: powerScore ?? this.powerScore,
      weeklyDistance: weeklyDistance ?? this.weeklyDistance,
      avgCadence: avgCadence ?? this.avgCadence,
      avgPace: avgPace ?? this.avgPace,
      pastInjuries: pastInjuries ?? this.pastInjuries,
      groundContactTime: groundContactTime ?? this.groundContactTime,
      verticalOscillation: verticalOscillation ?? this.verticalOscillation,
      strideLength: strideLength ?? this.strideLength,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
