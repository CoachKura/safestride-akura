// Training Load Service
// Calculates TRIMP, ACWR, and provides training recommendations
// Manages training load monitoring and fatigue tracking

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:developer' as developer;

enum TrainingStatus {
  undertrained, // ACWR < 0.8
  optimal, // ACWR 0.8-1.3
  increased, // ACWR 1.3-1.5
  high, // ACWR > 1.5
}

class TrainingLoadData {
  final double acuteLoad; // 7-day average
  final double chronicLoad; // 28-day average
  final double acwr; // Acute:Chronic Workload Ratio
  final TrainingStatus status;
  final String statusMessage;
  final String recommendation;
  final List<double> weeklyLoads; // Last 4 weeks

  TrainingLoadData({
    required this.acuteLoad,
    required this.chronicLoad,
    required this.acwr,
    required this.status,
    required this.statusMessage,
    required this.recommendation,
    required this.weeklyLoads,
  });

  Map<String, dynamic> toJson() {
    return {
      'acute_load': acuteLoad,
      'chronic_load': chronicLoad,
      'acwr': acwr,
      'status': status.name,
      'status_message': statusMessage,
      'recommendation': recommendation,
      'weekly_loads': weeklyLoads,
    };
  }
}

class TrainingRecommendation {
  final TrainingStatus status;
  final String title;
  final String message;
  final String action;
  final List<String> specificActions;
  final String? warningLevel; // 'info', 'warning', 'danger'

  TrainingRecommendation({
    required this.status,
    required this.title,
    required this.message,
    required this.action,
    required this.specificActions,
    this.warningLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'title': title,
      'message': message,
      'action': action,
      'specific_actions': specificActions,
      'warning_level': warningLevel,
    };
  }
}

class WeeklyStats {
  final double totalDistance;
  final int totalTime; // minutes
  final int elevationGain;
  final double avgPace;
  final double? avgHeartRate;
  final int activityCount;
  final int restDays;
  final double trainingLoad;

  WeeklyStats({
    required this.totalDistance,
    required this.totalTime,
    required this.elevationGain,
    required this.avgPace,
    this.avgHeartRate,
    required this.activityCount,
    required this.restDays,
    required this.trainingLoad,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_distance': totalDistance,
      'total_time': totalTime,
      'elevation_gain': elevationGain,
      'avg_pace': avgPace,
      'avg_heart_rate': avgHeartRate,
      'activity_count': activityCount,
      'rest_days': restDays,
      'training_load': trainingLoad,
    };
  }
}

class TrainingLoadService {
  final _supabase = Supabase.instance.client;

  // Calculate Acute:Chronic Workload Ratio
  Future<TrainingLoadData> calculateACWR(String userId) async {
    try {
      // Get training loads for last 28 days
      final loads = await _getTrainingLoads(userId, days: 28);

      if (loads.isEmpty) {
        return TrainingLoadData(
          acuteLoad: 0,
          chronicLoad: 0,
          acwr: 0,
          status: TrainingStatus.undertrained,
          statusMessage: 'No training data available',
          recommendation: 'Start tracking your activities',
          weeklyLoads: [0, 0, 0, 0],
        );
      }

      // Calculate acute load (last 7 days)
      final acuteLoad = _calculateAverageLoad(loads.take(7).toList());

      // Calculate chronic load (last 28 days)
      final chronicLoad = _calculateAverageLoad(loads);

      // Calculate ACWR
      final acwr = chronicLoad > 0 ? acuteLoad / chronicLoad : 0;

      // Get weekly loads for chart
      final weeklyLoads = [
        _calculateAverageLoad(loads.skip(21).take(7).toList()),
        _calculateAverageLoad(loads.skip(14).take(7).toList()),
        _calculateAverageLoad(loads.skip(7).take(7).toList()),
        acuteLoad,
      ];

      // Determine status
      final status = _getTrainingStatus(acwr.toDouble());
      final statusMessage = _getStatusMessage(status, acwr.toDouble());
      final recommendation = _getRecommendation(status, acwr.toDouble());

      return TrainingLoadData(
        acuteLoad: acuteLoad,
        chronicLoad: chronicLoad,
        acwr: acwr.toDouble(),
        status: status,
        statusMessage: statusMessage,
        recommendation: recommendation,
        weeklyLoads: weeklyLoads,
      );
    } catch (e) {
      developer.log('❌ Error calculating ACWR: $e');
      rethrow;
    }
  }

  // Calculate TRIMP (Training Impulse) for an activity
  double calculateTRIMP({
    required int durationMinutes,
    required double avgHeartRate,
    required double maxHeartRate,
    required double restingHeartRate,
  }) {
    try {
      final hrReserve = maxHeartRate - restingHeartRate;
      if (hrReserve <= 0) return 0;

      final hrIntensity = (avgHeartRate - restingHeartRate) / hrReserve;
      final intensity = hrIntensity.clamp(0.0, 1.0);

      // Edwards TRIMP formula
      final trimp = durationMinutes * intensity * 0.64 * exp(1.92 * intensity);

      return trimp;
    } catch (e) {
      developer.log('❌ Error calculating TRIMP: $e');
      return 0;
    }
  }

  // Calculate simplified training load (distance-based)
  double calculateSimpleTrainingLoad({
    required double distanceKm,
    required int durationMinutes,
    int elevationGain = 0,
  }) {
    // Base load from distance
    double load = distanceKm * 10;

    // Adjust for pace (faster = more load)
    final paceMin = durationMinutes / distanceKm;
    if (paceMin < 4.5) {
      load *= 1.3; // Fast pace
    } else if (paceMin < 5.5) {
      load *= 1.1; // Moderate pace
    }

    // Add elevation factor (10m elevation = 100m distance)
    load += (elevationGain / 10);

    return load;
  }

  // Get training recommendation
  Future<TrainingRecommendation> getTrainingRecommendation(
      String userId) async {
    try {
      final loadData = await calculateACWR(userId);

      switch (loadData.status) {
        case TrainingStatus.undertrained:
          return TrainingRecommendation(
            status: TrainingStatus.undertrained,
            title: 'Low Training Load',
            message:
                'Your training load is below optimal. You have room to increase volume safely.',
            action: 'Gradually increase weekly mileage by 10-15%',
            specificActions: [
              'Add 1-2 km to easy runs',
              'Include an extra workout day if rested',
              'Maintain current intensity while increasing volume',
            ],
            warningLevel: 'info',
          );

        case TrainingStatus.optimal:
          return TrainingRecommendation(
            status: TrainingStatus.optimal,
            title: 'Optimal Training Load',
            message:
                'Your training load is well balanced. Continue current progression.',
            action: 'Maintain current training plan',
            specificActions: [
              'Continue with planned workouts',
              'Monitor fatigue and soreness',
              'Adjust if feeling unusually tired',
            ],
            warningLevel: 'info',
          );

        case TrainingStatus.increased:
          return TrainingRecommendation(
            status: TrainingStatus.increased,
            title: 'Elevated Training Load',
            message: 'Training load is elevated. Monitor for signs of fatigue.',
            action: 'Maintain current volume or slightly reduce',
            specificActions: [
              'Add an extra rest day this week',
              'Keep next week volume same or reduce 10%',
              'Focus on recovery: sleep, nutrition, stretching',
              'Watch for persistent soreness or fatigue',
            ],
            warningLevel: 'warning',
          );

        case TrainingStatus.high:
          return TrainingRecommendation(
            status: TrainingStatus.high,
            title: '⚠️ High Injury Risk Zone',
            message:
                'Training load spike detected! Significantly elevated injury risk.',
            action: 'Reduce training volume immediately',
            specificActions: [
              'Cut next week\'s mileage by 20-30%',
              'Add 2 rest days this week',
              'Replace hard workouts with easy runs',
              'Consider cross-training (swimming, cycling)',
              'Focus on recovery modalities',
              'Consult coach if training for race',
            ],
            warningLevel: 'danger',
          );
      }
    } catch (e) {
      developer.log('❌ Error getting training recommendation: $e');
      rethrow;
    }
  }

  // Get weekly statistics
  Future<WeeklyStats> getWeeklyStats(String userId,
      {int weekOffset = 0}) async {
    try {
      final endDate = DateTime.now().subtract(Duration(days: 7 * weekOffset));
      final startDate = endDate.subtract(const Duration(days: 7));

      final activities = await _supabase
          .from('gps_activities')
          .select()
          .eq('user_id', userId)
          .gte('start_time', startDate.toIso8601String())
          .lt('start_time', endDate.toIso8601String());

      if (activities.isEmpty) {
        return WeeklyStats(
          totalDistance: 0,
          totalTime: 0,
          elevationGain: 0,
          avgPace: 0,
          activityCount: 0,
          restDays: 7,
          trainingLoad: 0,
        );
      }

      final activitiesList = activities as List;

      // Calculate totals
      final totalDistance = activitiesList.fold<double>(
          0, (sum, act) => sum + (act['distance_km'] ?? 0));

      final totalTime = activitiesList.fold<int>(
          0, (sum, act) => sum + (act['duration_minutes'] ?? 0).toInt());

      final elevationGain = activitiesList.fold<int>(
          0, (sum, act) => sum + (act['elevation_gain'] ?? 0).toInt());

      // Calculate average pace
      final avgPace =
          totalDistance > 0 ? (totalTime * 60 / totalDistance).toDouble() : 0;

      // Calculate average heart rate
      final heartRates = activitiesList
          .where((act) => act['avg_heart_rate'] != null)
          .map((act) => act['avg_heart_rate'] as num)
          .toList();

      final avgHeartRate = heartRates.isNotEmpty
          ? heartRates.reduce((a, b) => a + b) / heartRates.length
          : null;

      // Calculate training load
      double trainingLoad = 0;
      for (final act in activitiesList) {
        final distance = act['distance_km'] ?? 0;
        final duration = act['duration_minutes'] ?? 0;
        final elevation = act['elevation_gain'] ?? 0;

        trainingLoad += calculateSimpleTrainingLoad(
          distanceKm: distance.toDouble(),
          durationMinutes: duration,
          elevationGain: elevation,
        );
      }

      return WeeklyStats(
        totalDistance: totalDistance,
        totalTime: totalTime,
        elevationGain: elevationGain,
        avgPace: avgPace.toDouble(),
        avgHeartRate: avgHeartRate?.toDouble(),
        activityCount: activitiesList.length,
        restDays: 7 - activitiesList.length,
        trainingLoad: trainingLoad,
      );
    } catch (e) {
      developer.log('❌ Error getting weekly stats: $e');
      rethrow;
    }
  }

  // Get last N weeks of stats
  Future<List<WeeklyStats>> getWeeklyStatsHistory(
    String userId, {
    int weeks = 4,
  }) async {
    final stats = <WeeklyStats>[];

    for (int i = 0; i < weeks; i++) {
      final weekStats = await getWeeklyStats(userId, weekOffset: i);
      stats.add(weekStats);
    }

    return stats.reversed.toList(); // Oldest to newest
  }

  // Private helper methods

  Future<List<double>> _getTrainingLoads(String userId,
      {required int days}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final activities = await _supabase
          .from('gps_activities')
          .select()
          .eq('user_id', userId)
          .gte('start_time', startDate.toIso8601String())
          .order('start_time', ascending: false);

      if (activities.isEmpty) return [];

      final activitiesList = activities as List;

      // Group by day and calculate daily load
      final dailyLoads = <double>[];

      for (int i = 0; i < days; i++) {
        final dayDate = DateTime.now().subtract(Duration(days: i));
        final dayActivities = activitiesList.where((act) {
          final actDate = DateTime.parse(act['start_time']);
          return actDate.year == dayDate.year &&
              actDate.month == dayDate.month &&
              actDate.day == dayDate.day;
        });

        double dayLoad = 0;
        for (final act in dayActivities) {
          dayLoad += calculateSimpleTrainingLoad(
            distanceKm: (act['distance_km'] ?? 0).toDouble(),
            durationMinutes: act['duration_minutes'] ?? 0,
            elevationGain: act['elevation_gain'] ?? 0,
          );
        }

        dailyLoads.add(dayLoad);
      }

      return dailyLoads;
    } catch (e) {
      developer.log('❌ Error getting training loads: $e');
      return [];
    }
  }

  double _calculateAverageLoad(List<double> loads) {
    if (loads.isEmpty) return 0;
    return loads.reduce((a, b) => a + b) / loads.length;
  }

  TrainingStatus _getTrainingStatus(double acwr) {
    if (acwr < 0.8) return TrainingStatus.undertrained;
    if (acwr <= 1.3) return TrainingStatus.optimal;
    if (acwr <= 1.5) return TrainingStatus.increased;
    return TrainingStatus.high;
  }

  String _getStatusMessage(TrainingStatus status, double acwr) {
    switch (status) {
      case TrainingStatus.undertrained:
        return 'ACWR: ${acwr.toStringAsFixed(2)} - Training load is low';
      case TrainingStatus.optimal:
        return 'ACWR: ${acwr.toStringAsFixed(2)} - Optimal training zone';
      case TrainingStatus.increased:
        return 'ACWR: ${acwr.toStringAsFixed(2)} - Elevated load - monitor fatigue';
      case TrainingStatus.high:
        return 'ACWR: ${acwr.toStringAsFixed(2)} - HIGH RISK - reduce volume';
    }
  }

  String _getRecommendation(TrainingStatus status, double acwr) {
    switch (status) {
      case TrainingStatus.undertrained:
        return 'You can safely increase training volume by 10-15%';
      case TrainingStatus.optimal:
        return 'Continue with your current training plan';
      case TrainingStatus.increased:
        return 'Maintain or slightly reduce volume. Add extra rest.';
      case TrainingStatus.high:
        return 'Reduce next week\'s volume by 20-30% to avoid injury';
    }
  }

  // Save training load to database (for historical tracking)
  Future<void> saveTrainingLoad(
    String userId,
    DateTime date,
    double load,
  ) async {
    try {
      await _supabase.from('training_loads').upsert({
        'user_id': userId,
        'date': date.toIso8601String().split('T')[0],
        'load': load,
      });

      developer.log(
          '✅ Training load saved for ${date.toIso8601String().split('T')[0]}');
    } catch (e) {
      developer.log('❌ Error saving training load: $e');
    }
  }
}
