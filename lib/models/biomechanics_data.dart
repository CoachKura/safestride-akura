// Biomechanics Data Model
// Track running form metrics and biomechanical data

import 'package:supabase_flutter/supabase_flutter.dart';

class BiomechanicsData {
  final String id;
  final String userId;
  final String? runSessionId; // Optional link to run session
  final DateTime timestamp;

  // Cadence (steps per minute)
  final int? cadence;
  final int? leftCadence;
  final int? rightCadence;

  // Stride metrics
  final double? strideLength; // meters
  final double? leftStrideLength;
  final double? rightStrideLength;

  // Ground contact time (milliseconds)
  final int? groundContactTime;
  final int? leftGroundContactTime;
  final int? rightGroundContactTime;

  // Vertical oscillation (cm)
  final double? verticalOscillation;
  final double? leftVerticalOscillation;
  final double? rightVerticalOscillation;

  // Ground contact balance (%)
  final double? groundContactBalance; // 50% = perfect balance

  // Power and efficiency
  final int? power; // Watts
  final double? verticalRatio; // Ratio of vertical oscillation to stride length

  // Impact forces (G-force)
  final double? impactForce; // Estimated from accelerometer
  final double? leftImpactForce;
  final double? rightImpactForce;

  // Pronation (degrees)
  final double? pronation;
  final String? pronationType; // 'neutral', 'overpronation', 'underpronation'

  // Location (optional, for context)
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speedKmh;

  BiomechanicsData({
    required this.id,
    required this.userId,
    this.runSessionId,
    required this.timestamp,
    this.cadence,
    this.leftCadence,
    this.rightCadence,
    this.strideLength,
    this.leftStrideLength,
    this.rightStrideLength,
    this.groundContactTime,
    this.leftGroundContactTime,
    this.rightGroundContactTime,
    this.verticalOscillation,
    this.leftVerticalOscillation,
    this.rightVerticalOscillation,
    this.groundContactBalance,
    this.power,
    this.verticalRatio,
    this.impactForce,
    this.leftImpactForce,
    this.rightImpactForce,
    this.pronation,
    this.pronationType,
    this.latitude,
    this.longitude,
    this.altitude,
    this.speedKmh,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'run_session_id': runSessionId,
      'timestamp': timestamp.toIso8601String(),
      'cadence': cadence,
      'left_cadence': leftCadence,
      'right_cadence': rightCadence,
      'stride_length': strideLength,
      'left_stride_length': leftStrideLength,
      'right_stride_length': rightStrideLength,
      'ground_contact_time': groundContactTime,
      'left_ground_contact_time': leftGroundContactTime,
      'right_ground_contact_time': rightGroundContactTime,
      'vertical_oscillation': verticalOscillation,
      'left_vertical_oscillation': leftVerticalOscillation,
      'right_vertical_oscillation': rightVerticalOscillation,
      'ground_contact_balance': groundContactBalance,
      'power': power,
      'vertical_ratio': verticalRatio,
      'impact_force': impactForce,
      'left_impact_force': leftImpactForce,
      'right_impact_force': rightImpactForce,
      'pronation': pronation,
      'pronation_type': pronationType,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed_kmh': speedKmh,
    };
  }

  factory BiomechanicsData.fromJson(Map<String, dynamic> json) {
    return BiomechanicsData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      runSessionId: json['run_session_id'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      cadence: json['cadence'] as int?,
      leftCadence: json['left_cadence'] as int?,
      rightCadence: json['right_cadence'] as int?,
      strideLength: json['stride_length'] != null
          ? (json['stride_length'] as num).toDouble()
          : null,
      leftStrideLength: json['left_stride_length'] != null
          ? (json['left_stride_length'] as num).toDouble()
          : null,
      rightStrideLength: json['right_stride_length'] != null
          ? (json['right_stride_length'] as num).toDouble()
          : null,
      groundContactTime: json['ground_contact_time'] as int?,
      leftGroundContactTime: json['left_ground_contact_time'] as int?,
      rightGroundContactTime: json['right_ground_contact_time'] as int?,
      verticalOscillation: json['vertical_oscillation'] != null
          ? (json['vertical_oscillation'] as num).toDouble()
          : null,
      leftVerticalOscillation: json['left_vertical_oscillation'] != null
          ? (json['left_vertical_oscillation'] as num).toDouble()
          : null,
      rightVerticalOscillation: json['right_vertical_oscillation'] != null
          ? (json['right_vertical_oscillation'] as num).toDouble()
          : null,
      groundContactBalance: json['ground_contact_balance'] != null
          ? (json['ground_contact_balance'] as num).toDouble()
          : null,
      power: json['power'] as int?,
      verticalRatio: json['vertical_ratio'] != null
          ? (json['vertical_ratio'] as num).toDouble()
          : null,
      impactForce: json['impact_force'] != null
          ? (json['impact_force'] as num).toDouble()
          : null,
      leftImpactForce: json['left_impact_force'] != null
          ? (json['left_impact_force'] as num).toDouble()
          : null,
      rightImpactForce: json['right_impact_force'] != null
          ? (json['right_impact_force'] as num).toDouble()
          : null,
      pronation: json['pronation'] != null
          ? (json['pronation'] as num).toDouble()
          : null,
      pronationType: json['pronation_type'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      altitude: json['altitude'] != null
          ? (json['altitude'] as num).toDouble()
          : null,
      speedKmh: json['speed_kmh'] != null
          ? (json['speed_kmh'] as num).toDouble()
          : null,
    );
  }

  // Calculate asymmetry score (0-100, 0 = perfect symmetry)
  double? get cadenceAsymmetry {
    if (leftCadence == null || rightCadence == null) return null;
    final total = leftCadence! + rightCadence!;
    if (total == 0) return null;
    final balance = (leftCadence! / total) * 100;
    return (balance - 50).abs() * 2; // 0 = perfect 50/50 balance
  }

  double? get strideAsymmetry {
    if (leftStrideLength == null || rightStrideLength == null) return null;
    final avg = (leftStrideLength! + rightStrideLength!) / 2;
    if (avg == 0) return null;
    final diff = (leftStrideLength! - rightStrideLength!).abs();
    return (diff / avg) * 100; // Percentage difference
  }

  double? get contactTimeAsymmetry {
    if (leftGroundContactTime == null || rightGroundContactTime == null) {
      return null;
    }
    final total = leftGroundContactTime! + rightGroundContactTime!;
    if (total == 0) return null;
    final balance = (leftGroundContactTime! / total) * 100;
    return (balance - 50).abs() * 2;
  }

  // Assess running form quality
  String get formQuality {
    int score = 0;
    int factors = 0;

    // Cadence (optimal: 170-180 spm)
    if (cadence != null) {
      factors++;
      if (cadence! >= 170 && cadence! <= 180) {
        score += 10;
      } else if (cadence! >= 160 && cadence! <= 190) {
        score += 7;
      } else {
        score += 4;
      }
    }

    // Ground contact time (optimal: < 250ms)
    if (groundContactTime != null) {
      factors++;
      if (groundContactTime! < 250) {
        score += 10;
      } else if (groundContactTime! < 300) {
        score += 7;
      } else {
        score += 4;
      }
    }

    // Vertical oscillation (optimal: < 10cm)
    if (verticalOscillation != null) {
      factors++;
      if (verticalOscillation! < 10) {
        score += 10;
      } else if (verticalOscillation! < 12) {
        score += 7;
      } else {
        score += 4;
      }
    }

    // Asymmetry (optimal: < 5%)
    final strideAsym = strideAsymmetry;
    if (strideAsym != null) {
      factors++;
      if (strideAsym < 5) {
        score += 10;
      } else if (strideAsym < 10) {
        score += 7;
      } else {
        score += 4;
      }
    }

    if (factors == 0) return 'Unknown';

    final avgScore = score / factors;
    if (avgScore >= 9) return 'Excellent';
    if (avgScore >= 7) return 'Good';
    if (avgScore >= 5) return 'Fair';
    return 'Needs Improvement';
  }

  // Get specific coaching feedback
  List<String> get coachingTips {
    final tips = <String>[];

    // Cadence feedback
    if (cadence != null) {
      if (cadence! < 160) {
        tips.add(
            '🦶 Increase cadence: Your cadence is ${cadence} spm. Try to aim for 170-180 spm by taking quicker, shorter steps.');
      } else if (cadence! > 190) {
        tips.add(
            '🦶 Slow down cadence: Your cadence is ${cadence} spm. This might be too high. Aim for 170-180 spm.');
      }
    }

    // Ground contact time
    if (groundContactTime != null && groundContactTime! > 300) {
      tips.add(
          '⚡ Reduce ground contact time: Spend less time on the ground (currently ${groundContactTime}ms). Focus on a quicker push-off.');
    }

    // Vertical oscillation
    if (verticalOscillation != null && verticalOscillation! > 12) {
      tips.add(
          '📏 Reduce vertical bounce: Your vertical oscillation is ${verticalOscillation!.toStringAsFixed(1)} cm. Try to run "forward" not "up".');
    }

    // Asymmetry
    final strideAsym = strideAsymmetry;
    if (strideAsym != null && strideAsym > 10) {
      tips.add(
          '⚠️ High stride asymmetry: ${strideAsym.toStringAsFixed(1)}% difference between legs. Consider form drills and strength work.');
    }

    // Impact forces
    if (impactForce != null && impactForce! > 3.0) {
      tips.add(
          '🛡️ High impact forces: ${impactForce!.toStringAsFixed(1)}G. Focus on softer landings and midfoot strike.');
    }

    // Pronation
    if (pronationType != null) {
      if (pronationType == 'overpronation') {
        tips.add(
            '👟 Overpronation detected: Consider stability shoes and strengthening exercises for your arches.');
      } else if (pronationType == 'underpronation') {
        tips.add(
            '👟 Underpronation detected: Consider cushioned shoes and stretching your calves.');
      }
    }

    return tips;
  }
}

class BiomechanicsService {
  static final _supabase = Supabase.instance.client;

  // Save biomechanics data
  static Future<bool> saveData(BiomechanicsData data) async {
    try {
      await _supabase.from('biomechanics_data').upsert(data.toJson());
      return true;
    } catch (e) {
      print('Error saving biomechanics data: $e');
      return false;
    }
  }

  // Get biomechanics data for a run session
  static Future<List<BiomechanicsData>> getSessionData({
    required String runSessionId,
  }) async {
    try {
      final response = await _supabase
          .from('biomechanics_data')
          .select()
          .eq('run_session_id', runSessionId)
          .order('timestamp', ascending: true);

      return (response as List)
          .map((json) => BiomechanicsData.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading biomechanics data: $e');
      return [];
    }
  }

  // Get average biomechanics for a user
  static Future<BiomechanicsAverage> getUserAverages({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query =
          _supabase.from('biomechanics_data').select().eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final response = await query;
      final dataList = (response as List)
          .map((json) => BiomechanicsData.fromJson(json))
          .toList();

      if (dataList.isEmpty) {
        return BiomechanicsAverage();
      }

      // Calculate averages
      final cadences =
          dataList.where((d) => d.cadence != null).map((d) => d.cadence!);
      final strideLengths = dataList
          .where((d) => d.strideLength != null)
          .map((d) => d.strideLength!);
      final contactTimes = dataList
          .where((d) => d.groundContactTime != null)
          .map((d) => d.groundContactTime!);
      final oscillations = dataList
          .where((d) => d.verticalOscillation != null)
          .map((d) => d.verticalOscillation!);

      return BiomechanicsAverage(
        avgCadence: cadences.isNotEmpty
            ? cadences.reduce((a, b) => a + b) / cadences.length
            : null,
        avgStrideLength: strideLengths.isNotEmpty
            ? strideLengths.reduce((a, b) => a + b) / strideLengths.length
            : null,
        avgGroundContactTime: contactTimes.isNotEmpty
            ? contactTimes.reduce((a, b) => a + b) / contactTimes.length
            : null,
        avgVerticalOscillation: oscillations.isNotEmpty
            ? oscillations.reduce((a, b) => a + b) / oscillations.length
            : null,
        dataPoints: dataList.length,
      );
    } catch (e) {
      print('Error calculating biomechanics averages: $e');
      return BiomechanicsAverage();
    }
  }
}

class BiomechanicsAverage {
  final double? avgCadence;
  final double? avgStrideLength;
  final double? avgGroundContactTime;
  final double? avgVerticalOscillation;
  final int dataPoints;

  BiomechanicsAverage({
    this.avgCadence,
    this.avgStrideLength,
    this.avgGroundContactTime,
    this.avgVerticalOscillation,
    this.dataPoints = 0,
  });
}
