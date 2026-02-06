class Activity {
  final String? id;
  final String athleteId;
  final DateTime activityDate;
  final double distanceKm;
  final int durationMinutes;
  final String activityType;
  final int rpe;
  final String notes;
  final List<Map<String, dynamic>>? gpsData;

  Activity({
    this.id,
    required this.athleteId,
    required this.activityDate,
    required this.distanceKm,
    required this.durationMinutes,
    required this.activityType,
    required this.rpe,
    required this.notes,
    this.gpsData,
  });

  Map<String, dynamic> toJson() {
    return {
      'athlete_id': athleteId,
      'activity_date': activityDate.toIso8601String(),
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'activity_type': activityType,
      'rpe': rpe,
      'notes': notes,
      'gps_data': gpsData,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      athleteId: json['athlete_id'],
      activityDate: DateTime.parse(json['activity_date']),
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationMinutes: json['duration_minutes'],
      activityType: json['activity_type'],
      rpe: json['rpe'],
      notes: json['notes'] ?? '',
      gpsData: json['gps_data'] != null 
          ? List<Map<String, dynamic>>.from(json['gps_data'])
          : null,
    );
  }
}
