// Run Session Model
// Tracks GPS-recorded running sessions with real-time metrics

import 'package:latlong2/latlong.dart';

enum RunSessionStatus {
  active,
  paused,
  completed,
  uploaded,
}

class RunSession {
  final String id;
  final String userId;
  final DateTime startTime;
  DateTime? endTime;

  // Workout context (optional - from training plan)
  final String? workoutName;
  final String? workoutType; // 'easy', 'tempo', 'interval', 'long_run'
  final double? plannedDistanceKm;
  final String? plannedPaceTarget; // e.g., 'Easy: 6:15/km'
  final Map<String, dynamic>?
      workoutContext; // Full workout context including week_number, training_plan_goal, etc.

  // GPS tracking
  final List<RoutePoint> route;

  // Metrics
  double distanceMeters;
  int durationSeconds; // Active time (excludes pauses)
  int totalSeconds; // Total elapsed time (includes pauses)
  List<int> pauseIntervals; // Seconds at each pause

  // Performance
  double? avgPaceMinPerKm;
  double? currentPaceMinPerKm;
  double? maxSpeedKmh;
  double? avgHeartRate;
  double? maxHeartRate;
  int? calories;

  // Splits
  List<SplitData> splits;

  // Status
  RunSessionStatus status;
  bool isUploaded;
  String? stravaActivityId;

  RunSession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.workoutName,
    this.workoutType,
    this.plannedDistanceKm,
    this.plannedPaceTarget,
    this.workoutContext,
    required this.route,
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.totalSeconds = 0,
    List<int>? pauseIntervals,
    this.avgPaceMinPerKm,
    this.currentPaceMinPerKm,
    this.maxSpeedKmh,
    this.avgHeartRate,
    this.maxHeartRate,
    this.calories,
    List<SplitData>? splits,
    this.status = RunSessionStatus.active,
    this.isUploaded = false,
    this.stravaActivityId,
  })  : pauseIntervals = pauseIntervals ?? [],
        splits = splits ?? [];

  // Calculate current pace from recent GPS points (last 30 seconds)
  void updateCurrentPace() {
    if (route.length < 2) return;

    final now = DateTime.now();
    final recentPoints = route
        .where((p) => now.difference(p.timestamp).inSeconds <= 30)
        .toList();

    if (recentPoints.length < 2) return;

    double recentDistance = 0;
    for (int i = 1; i < recentPoints.length; i++) {
      recentDistance += _calculateDistance(
        recentPoints[i - 1].latLng,
        recentPoints[i].latLng,
      );
    }

    final recentTime = recentPoints.last.timestamp
        .difference(recentPoints.first.timestamp)
        .inSeconds;

    if (recentTime > 0 && recentDistance > 0) {
      // Pace in min/km
      currentPaceMinPerKm = (recentTime / 60) / (recentDistance / 1000);
    }
  }

  // Add new GPS point and update metrics
  void addRoutePoint(RoutePoint point) {
    if (route.isNotEmpty) {
      final lastPoint = route.last;
      final distance = _calculateDistance(lastPoint.latLng, point.latLng);
      distanceMeters += distance;

      // Update max speed
      final timeDiff =
          point.timestamp.difference(lastPoint.timestamp).inSeconds;
      if (timeDiff > 0) {
        final speedKmh = (distance / 1000) / (timeDiff / 3600);
        if (maxSpeedKmh == null || speedKmh > maxSpeedKmh!) {
          maxSpeedKmh = speedKmh;
        }
      }
    }

    route.add(point);
    updateCurrentPace();

    // Update average pace
    if (durationSeconds > 0 && distanceMeters > 0) {
      avgPaceMinPerKm = (durationSeconds / 60) / (distanceMeters / 1000);
    }

    // Auto-generate splits every 1km
    _checkAndAddSplit();
  }

  void _checkAndAddSplit() {
    final currentKm = (distanceMeters / 1000).floor();
    final lastSplitKm = splits.isEmpty ? 0 : splits.last.distanceKm;

    if (currentKm > lastSplitKm) {
      // Calculate split time
      final splitDuration = durationSeconds -
          (splits.isEmpty ? 0 : splits.last.cumulativeSeconds);

      splits.add(SplitData(
        splitNumber: splits.length + 1,
        distanceKm: currentKm,
        durationSeconds: splitDuration,
        cumulativeSeconds: durationSeconds,
        avgPaceMinPerKm: (splitDuration / 60) / 1.0, // 1km split
      ));
    }
  }

  // Distance calculation using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  // Complete the session
  void complete() {
    endTime = DateTime.now();
    status = RunSessionStatus.completed;

    // Estimate calories (rough formula: 1 cal per kg per km)
    // Assume 70kg average if not provided
    calories = ((distanceMeters / 1000) * 70).round();
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'workout_name': workoutName,
      'workout_type': workoutType,
      'planned_distance_km': plannedDistanceKm,
      'planned_pace_target': plannedPaceTarget,
      'workout_context': workoutContext,
      'route': route.map((p) => p.toJson()).toList(),
      'distance_meters': distanceMeters,
      'duration_seconds': durationSeconds,
      'total_seconds': totalSeconds,
      'pause_intervals': pauseIntervals,
      'avg_pace_min_per_km': avgPaceMinPerKm,
      'max_speed_kmh': maxSpeedKmh,
      'avg_heart_rate': avgHeartRate,
      'max_heart_rate': maxHeartRate,
      'calories': calories,
      'splits': splits.map((s) => s.toJson()).toList(),
      'status': status.toString().split('.').last,
      'is_uploaded': isUploaded,
      'strava_activity_id': stravaActivityId,
    };
  }

  // Create from JSON
  factory RunSession.fromJson(Map<String, dynamic> json) {
    return RunSession(
      id: json['id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      workoutName: json['workout_name'],
      workoutType: json['workout_type'],
      plannedDistanceKm: json['planned_distance_km']?.toDouble(),
      plannedPaceTarget: json['planned_pace_target'],
      workoutContext: json['workout_context'] as Map<String, dynamic>?,
      route: (json['route'] as List?)
              ?.map((p) => RoutePoint.fromJson(p))
              .toList() ??
          [],
      distanceMeters: json['distance_meters']?.toDouble() ?? 0,
      durationSeconds: json['duration_seconds'] ?? 0,
      totalSeconds: json['total_seconds'] ?? 0,
      pauseIntervals: List<int>.from(json['pause_intervals'] ?? []),
      avgPaceMinPerKm: json['avg_pace_min_per_km']?.toDouble(),
      currentPaceMinPerKm: null,
      maxSpeedKmh: json['max_speed_kmh']?.toDouble(),
      avgHeartRate: json['avg_heart_rate']?.toDouble(),
      maxHeartRate: json['max_heart_rate']?.toDouble(),
      calories: json['calories'],
      splits: (json['splits'] as List?)
              ?.map((s) => SplitData.fromJson(s))
              .toList() ??
          [],
      status: RunSessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RunSessionStatus.completed,
      ),
      isUploaded: json['is_uploaded'] ?? false,
      stravaActivityId: json['strava_activity_id'],
    );
  }
}

class RoutePoint {
  final LatLng latLng;
  final DateTime timestamp;
  final double? altitude;
  final double? accuracy;
  final double? speed; // m/s
  final double? heartRate;

  RoutePoint({
    required this.latLng,
    required this.timestamp,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heartRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': latLng.latitude,
      'lng': latLng.longitude,
      'timestamp': timestamp.toIso8601String(),
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'heart_rate': heartRate,
    };
  }

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latLng: LatLng(json['lat'], json['lng']),
      timestamp: DateTime.parse(json['timestamp']),
      altitude: json['altitude']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heartRate: json['heart_rate']?.toDouble(),
    );
  }
}

class SplitData {
  final int splitNumber; // 1, 2, 3...
  final int distanceKm;
  final int durationSeconds; // Time for this split
  final int cumulativeSeconds; // Total time up to this split
  final double avgPaceMinPerKm;

  SplitData({
    required this.splitNumber,
    required this.distanceKm,
    required this.durationSeconds,
    required this.cumulativeSeconds,
    required this.avgPaceMinPerKm,
  });

  String get paceFormatted {
    final m = avgPaceMinPerKm.floor();
    final s = ((avgPaceMinPerKm - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')}/km';
  }

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'split_number': splitNumber,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'cumulative_seconds': cumulativeSeconds,
      'avg_pace_min_per_km': avgPaceMinPerKm,
    };
  }

  factory SplitData.fromJson(Map<String, dynamic> json) {
    return SplitData(
      splitNumber: json['split_number'],
      distanceKm: json['distance_km'],
      durationSeconds: json['duration_seconds'],
      cumulativeSeconds: json['cumulative_seconds'],
      avgPaceMinPerKm: json['avg_pace_min_per_km'].toDouble(),
    );
  }
}
