// lib/models/body_measurement.dart

class BodyMeasurement {
  final String id;
  final String userId;
  
  // Core Measurements
  final double weightKg;
  final int heightCm;
  
  // Calculated Metrics
  final double bmi;
  final String bmiCategory;
  
  // Optional Body Composition
  final double? bodyFatPercentage;
  final double? muscleMassKg;
  final double? boneMassKg;
  final double? waterPercentage;
  final int? visceralFatRating;
  
  // Body Measurements
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? thighCm;
  final double? calfCm;
  
  // Measurement Context
  final DateTime measurementDate;
  final DateTime? measurementTime;
  final String? measurementConditions;
  
  // Device/Method
  final String? measuredBy;
  final String? deviceModel;
  
  // Notes
  final String? notes;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  BodyMeasurement({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.heightCm,
    required this.bmi,
    required this.bmiCategory,
    this.bodyFatPercentage,
    this.muscleMassKg,
    this.boneMassKg,
    this.waterPercentage,
    this.visceralFatRating,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.thighCm,
    this.calfCm,
    required this.measurementDate,
    this.measurementTime,
    this.measurementConditions,
    this.measuredBy,
    this.deviceModel,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Helper getters
  String get formattedWeight => '${weightKg.toStringAsFixed(1)} kg';
  String get formattedHeight => '${heightCm} cm';
  String get formattedBMI => bmi.toStringAsFixed(1);
  
  String get bmiCategoryDisplay {
    switch (bmiCategory) {
      case 'underweight':
        return 'Underweight';
      case 'normal':
        return 'Normal';
      case 'overweight':
        return 'Overweight';
      case 'obese':
        return 'Obese';
      default:
        return bmiCategory;
    }
  }

  String get bmiCategoryColor {
    switch (bmiCategory) {
      case 'underweight':
        return '#FFC107';
      case 'normal':
        return '#4CAF50';
      case 'overweight':
        return '#FF9800';
      case 'obese':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  bool get hasBodyComposition => 
    bodyFatPercentage != null || 
    muscleMassKg != null || 
    waterPercentage != null;

  bool get hasBodyMeasurements =>
    chestCm != null || 
    waistCm != null || 
    hipsCm != null;

  // Supabase JSON serialization
  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      heightCm: json['height_cm'] as int,
      bmi: (json['bmi'] as num).toDouble(),
      bmiCategory: json['bmi_category'] as String,
      bodyFatPercentage: json['body_fat_percentage'] != null
          ? (json['body_fat_percentage'] as num).toDouble()
          : null,
      muscleMassKg: json['muscle_mass_kg'] != null
          ? (json['muscle_mass_kg'] as num).toDouble()
          : null,
      boneMassKg: json['bone_mass_kg'] != null
          ? (json['bone_mass_kg'] as num).toDouble()
          : null,
      waterPercentage: json['water_percentage'] != null
          ? (json['water_percentage'] as num).toDouble()
          : null,
      visceralFatRating: json['visceral_fat_rating'] as int?,
      chestCm: json['chest_cm'] != null
          ? (json['chest_cm'] as num).toDouble()
          : null,
      waistCm: json['waist_cm'] != null
          ? (json['waist_cm'] as num).toDouble()
          : null,
      hipsCm: json['hips_cm'] != null
          ? (json['hips_cm'] as num).toDouble()
          : null,
      thighCm: json['thigh_cm'] != null
          ? (json['thigh_cm'] as num).toDouble()
          : null,
      calfCm: json['calf_cm'] != null
          ? (json['calf_cm'] as num).toDouble()
          : null,
      measurementDate: DateTime.parse(json['measurement_date'] as String),
      measurementTime: json['measurement_time'] != null
          ? DateTime.parse('1970-01-01 ${json['measurement_time']}')
          : null,
      measurementConditions: json['measurement_conditions'] as String?,
      measuredBy: json['measured_by'] as String?,
      deviceModel: json['device_model'] as String?,
      notes: json['notes'] as String?,
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
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass_kg': muscleMassKg,
      'bone_mass_kg': boneMassKg,
      'water_percentage': waterPercentage,
      'visceral_fat_rating': visceralFatRating,
      'chest_cm': chestCm,
      'waist_cm': waistCm,
      'hips_cm': hipsCm,
      'thigh_cm': thighCm,
      'calf_cm': calfCm,
      'measurement_date': measurementDate.toIso8601String().split('T')[0],
      'measurement_time': measurementTime?.toIso8601String().split('T')[1],
      'measurement_conditions': measurementConditions,
      'measured_by': measuredBy,
      'device_model': deviceModel,
      'notes': notes,
    };
  }

  BodyMeasurement copyWith({
    String? id,
    String? userId,
    double? weightKg,
    int? heightCm,
    double? bmi,
    String? bmiCategory,
    double? bodyFatPercentage,
    double? muscleMassKg,
    double? boneMassKg,
    double? waterPercentage,
    int? visceralFatRating,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? thighCm,
    double? calfCm,
    DateTime? measurementDate,
    DateTime? measurementTime,
    String? measurementConditions,
    String? measuredBy,
    String? deviceModel,
    String? notes,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bmi: bmi ?? this.bmi,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      boneMassKg: boneMassKg ?? this.boneMassKg,
      waterPercentage: waterPercentage ?? this.waterPercentage,
      visceralFatRating: visceralFatRating ?? this.visceralFatRating,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      thighCm: thighCm ?? this.thighCm,
      calfCm: calfCm ?? this.calfCm,
      measurementDate: measurementDate ?? this.measurementDate,
      measurementTime: measurementTime ?? this.measurementTime,
      measurementConditions: measurementConditions ?? this.measurementConditions,
      measuredBy: measuredBy ?? this.measuredBy,
      deviceModel: deviceModel ?? this.deviceModel,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
