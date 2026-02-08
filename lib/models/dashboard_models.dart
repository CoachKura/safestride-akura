// lib/models/dashboard_models.dart

class DailyStats {
  final DateTime date;
  final int steps;
  final double distanceKm;
  final int activeCalories;
  final int totalCalories;
  final int caloriesConsumed;
  final Duration activeDuration;
  final int activitiesCount;
  final double avgHeartRate;
  final Duration sleepDuration;

  DailyStats({
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.activeCalories,
    required this.totalCalories,
    required this.caloriesConsumed,
    required this.activeDuration,
    required this.activitiesCount,
    this.avgHeartRate = 0,
    this.sleepDuration = Duration.zero,
  });

  int get caloriesRemaining => totalCalories - caloriesConsumed;

  double get stepsProgress => steps / 10000; // Default goal: 10k steps

  String get activeDurationDisplay {
    final hours = activeDuration.inHours;
    final minutes = activeDuration.inMinutes % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}m';
  }

  factory DailyStats.empty(DateTime date) {
    return DailyStats(
      date: date,
      steps: 0,
      distanceKm: 0,
      activeCalories: 0,
      totalCalories: 2000,
      caloriesConsumed: 0,
      activeDuration: Duration.zero,
      activitiesCount: 0,
    );
  }

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date'] as String),
      steps: json['steps'] as int? ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      activeCalories: json['active_calories'] as int? ?? 0,
      totalCalories: json['total_calories'] as int? ?? 2000,
      caloriesConsumed: json['calories_consumed'] as int? ?? 0,
      activeDuration: Duration(minutes: json['active_minutes'] as int? ?? 0),
      activitiesCount: json['activities_count'] as int? ?? 0,
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toDouble() ?? 0,
      sleepDuration: Duration(minutes: json['sleep_minutes'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'distance_km': distanceKm,
      'active_calories': activeCalories,
      'total_calories': totalCalories,
      'calories_consumed': caloriesConsumed,
      'active_minutes': activeDuration.inMinutes,
      'activities_count': activitiesCount,
      'avg_heart_rate': avgHeartRate,
      'sleep_minutes': sleepDuration.inMinutes,
    };
  }
}

/// Model for weekly summary statistics
class WeeklySummary {
  final List<DailyStats> days;

  WeeklySummary({required this.days});

  int get totalSteps => days.fold(0, (sum, day) => sum + day.steps);

  double get totalDistance =>
      days.fold(0.0, (sum, day) => sum + day.distanceKm);

  int get totalCalories => days.fold(0, (sum, day) => sum + day.activeCalories);

  Duration get totalActiveDuration {
    return days.fold(Duration.zero, (sum, day) => sum + day.activeDuration);
  }

  double get avgStepsPerDay => days.isEmpty ? 0 : totalSteps / days.length;

  int get activeDaysCount =>
      days.where((d) => d.steps > 0 || d.activitiesCount > 0).length;

  double get avgHeartRate {
    final daysWithHR = days.where((d) => d.avgHeartRate > 0);
    if (daysWithHR.isEmpty) return 0;
    return daysWithHR.map((d) => d.avgHeartRate).reduce((a, b) => a + b) /
        daysWithHR.length;
  }

  List<double> get stepsData => days.map((d) => d.steps.toDouble()).toList();
  List<double> get distanceData => days.map((d) => d.distanceKm).toList();
  List<double> get caloriesData =>
      days.map((d) => d.activeCalories.toDouble()).toList();
}

/// Dashboard data model containing all metrics
class FitnessDashboardData {
  final int steps;
  final int stepsGoal;
  final double distance;
  final double distanceGoal;
  final int calories;
  final int caloriesGoal;
  final int activeCalories;
  final int activitiesCount;
  final int caloriesRemaining;
  final int caloriesConsumed;
  final List<double> monthlyActivities;
  final List<double> weeklySteps;
  final Duration activeDuration;
  final int currentStreak;
  final double avgHeartRate;
  final Duration sleepDuration;

  FitnessDashboardData({
    required this.steps,
    required this.stepsGoal,
    required this.distance,
    required this.distanceGoal,
    required this.calories,
    required this.caloriesGoal,
    this.activeCalories = 0,
    this.activitiesCount = 0,
    this.caloriesRemaining = 0,
    this.caloriesConsumed = 0,
    required this.monthlyActivities,
    this.weeklySteps = const [],
    this.activeDuration = Duration.zero,
    this.currentStreak = 0,
    this.avgHeartRate = 0,
    this.sleepDuration = Duration.zero,
  });

  double get stepsProgress => stepsGoal > 0 ? steps / stepsGoal : 0;
  double get distanceProgress => distanceGoal > 0 ? distance / distanceGoal : 0;
  double get caloriesProgress => caloriesGoal > 0 ? calories / caloriesGoal : 0;

  factory FitnessDashboardData.mock() {
    return FitnessDashboardData(
      steps: 9156,
      stepsGoal: 10000,
      distance: 8.12,
      distanceGoal: 10.0,
      calories: 484,
      caloriesGoal: 2000,
      activeCalories: 484,
      activitiesCount: 1,
      caloriesRemaining: 1684,
      caloriesConsumed: 316,
      monthlyActivities: List.generate(30, (i) => 5000.0 + (i % 10) * 1000),
      weeklySteps: [8000, 9200, 7500, 10200, 8800, 6500, 9156],
      activeDuration: const Duration(hours: 1, minutes: 12),
      currentStreak: 5,
      avgHeartRate: 142,
      sleepDuration: const Duration(hours: 7, minutes: 30),
    );
  }

  factory FitnessDashboardData.empty() {
    return FitnessDashboardData(
      steps: 0,
      stepsGoal: 10000,
      distance: 0,
      distanceGoal: 10.0,
      calories: 0,
      caloriesGoal: 2000,
      monthlyActivities: List.generate(30, (_) => 0.0),
    );
  }
}

/// Model for activity summary (used in recent activities list)
class ActivitySummary {
  final String id;
  final String name;
  final String type;
  final DateTime startTime;
  final Duration duration;
  final double distanceKm;
  final int calories;
  final double? avgHeartRate;
  final double? avgPace; // min/km
  final String? source; // 'strava', 'garmin', etc.

  ActivitySummary({
    required this.id,
    required this.name,
    required this.type,
    required this.startTime,
    required this.duration,
    required this.distanceKm,
    required this.calories,
    this.avgHeartRate,
    this.avgPace,
    this.source,
  });

  String get durationDisplay {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get paceDisplay {
    if (avgPace == null || avgPace! <= 0) return '--:--';
    final mins = avgPace!.floor();
    final secs = ((avgPace! - mins) * 60).round();
    return '$mins:${secs.toString().padLeft(2, '0')} /km';
  }

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Activity',
      type: json['type'] as String? ?? 'run',
      startTime: DateTime.parse(json['start_time'] as String),
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 0),
      distanceKm: (json['distance_meters'] as num? ?? 0) / 1000,
      calories: json['calories'] as int? ?? 0,
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toDouble(),
      avgPace: (json['avg_pace'] as num?)?.toDouble(),
      source: json['source'] as String?,
    );
  }
}
