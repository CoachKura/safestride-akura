// Analytics Service
// Provides performance analytics, trends, and personal bests

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/run_session.dart';
import '../services/run_session_service.dart';

class AnalyticsService {
  // Get weekly mileage for the past N weeks
  static Future<List<WeeklyData>> getWeeklyMileage({
    required String userId,
    int weeks = 12,
  }) async {
    try {
      final sessions = await RunSessionService.loadUserSessions(
        userId: userId,
        limit: 1000,
      );

      // Group by week
      final weeklyMap = <String, WeeklyData>{};
      for (var session in sessions) {
        final weekKey = _getWeekKey(session.startTime);
        if (!weeklyMap.containsKey(weekKey)) {
          weeklyMap[weekKey] = WeeklyData(
            weekStart: _getWeekStart(session.startTime),
            distance: 0,
            duration: 0,
            runs: 0,
          );
        }
        weeklyMap[weekKey]!.distance += session.distanceMeters / 1000;
        weeklyMap[weekKey]!.duration += session.durationSeconds;
        weeklyMap[weekKey]!.runs += 1;
      }

      // Sort by date and take last N weeks
      final weeklyList = weeklyMap.values.toList()
        ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
      return weeklyList.reversed.take(weeks).toList().reversed.toList();
    } catch (e) {
      return [];
    }
  }

  // Get pace trends over time
  static Future<List<PaceTrend>> getPaceTrends({
    required String userId,
    int months = 6,
  }) async {
    try {
      final sessions = await RunSessionService.loadUserSessions(
        userId: userId,
        limit: 1000,
      );

      // Filter by date range
      final cutoff = DateTime.now().subtract(Duration(days: months * 30));
      final recentSessions = sessions
          .where((s) =>
              s.startTime.isAfter(cutoff) &&
              s.avgPaceMinPerKm != null &&
              s.avgPaceMinPerKm! > 0)
          .toList();

      // Group by month
      final monthlyMap = <String, List<double>>{};
      for (var session in recentSessions) {
        final monthKey =
            '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}';
        if (!monthlyMap.containsKey(monthKey)) {
          monthlyMap[monthKey] = [];
        }
        monthlyMap[monthKey]!.add(session.avgPaceMinPerKm!);
      }

      // Calculate average pace per month
      final trends = <PaceTrend>[];
      for (var entry in monthlyMap.entries) {
        final parts = entry.key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final avgPace =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
        trends.add(PaceTrend(
          date: DateTime(year, month),
          avgPaceMinPerKm: avgPace,
          runCount: entry.value.length,
        ));
      }

      trends.sort((a, b) => a.date.compareTo(b.date));
      return trends;
    } catch (e) {
      return [];
    }
  }

  // Get personal bests
  static Future<PersonalBests> getPersonalBests({
    required String userId,
  }) async {
    try {
      final sessions = await RunSessionService.loadUserSessions(
        userId: userId,
        limit: 1000,
      );

      if (sessions.isEmpty) {
        return PersonalBests();
      }

      // Find bests
      RunSession? fastest5k;
      RunSession? fastest10k;
      RunSession? fastestHalfMarathon;
      RunSession? longestRun;
      double fastestPace = double.infinity;
      RunSession? fastestPaceRun;

      for (var session in sessions) {
        final distanceKm = session.distanceMeters / 1000;

        // 5K (4.5 - 5.5 km range)
        if (distanceKm >= 4.5 && distanceKm <= 5.5) {
          if (fastest5k == null ||
              session.durationSeconds < fastest5k.durationSeconds) {
            fastest5k = session;
          }
        }

        // 10K (9.5 - 10.5 km range)
        if (distanceKm >= 9.5 && distanceKm <= 10.5) {
          if (fastest10k == null ||
              session.durationSeconds < fastest10k.durationSeconds) {
            fastest10k = session;
          }
        }

        // Half Marathon (20 - 22 km range)
        if (distanceKm >= 20 && distanceKm <= 22) {
          if (fastestHalfMarathon == null ||
              session.durationSeconds < fastestHalfMarathon.durationSeconds) {
            fastestHalfMarathon = session;
          }
        }

        // Longest run
        if (longestRun == null ||
            session.distanceMeters > longestRun.distanceMeters) {
          longestRun = session;
        }

        // Fastest pace (for runs > 3km to avoid sprint anomalies)
        if (distanceKm >= 3 &&
            session.avgPaceMinPerKm != null &&
            session.avgPaceMinPerKm! > 0) {
          if (session.avgPaceMinPerKm! < fastestPace) {
            fastestPace = session.avgPaceMinPerKm!;
            fastestPaceRun = session;
          }
        }
      }

      return PersonalBests(
        fastest5k: fastest5k,
        fastest10k: fastest10k,
        fastestHalfMarathon: fastestHalfMarathon,
        longestRun: longestRun,
        fastestPaceRun: fastestPaceRun,
      );
    } catch (e) {
      return PersonalBests();
    }
  }

  // Get training load (simple version based on distance and duration)
  static Future<List<TrainingLoad>> getTrainingLoad({
    required String userId,
    int weeks = 8,
  }) async {
    try {
      final sessions = await RunSessionService.loadUserSessions(
        userId: userId,
        limit: 1000,
      );

      // Group by week
      final weeklyMap = <String, TrainingLoad>{};
      for (var session in sessions) {
        final weekKey = _getWeekKey(session.startTime);
        if (!weeklyMap.containsKey(weekKey)) {
          weeklyMap[weekKey] = TrainingLoad(
            weekStart: _getWeekStart(session.startTime),
            load: 0,
            distance: 0,
            duration: 0,
          );
        }
        // Simple load calculation: distance (km) × duration (hours)
        final distanceKm = session.distanceMeters / 1000;
        final durationHours = session.durationSeconds / 3600;
        weeklyMap[weekKey]!.load += distanceKm * durationHours;
        weeklyMap[weekKey]!.distance += distanceKm;
        weeklyMap[weekKey]!.duration += session.durationSeconds;
      }

      // Sort and take last N weeks
      final loadList = weeklyMap.values.toList()
        ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
      return loadList.reversed.take(weeks).toList().reversed.toList();
    } catch (e) {
      return [];
    }
  }

  // Helper: Get week key (YYYY-WW format)
  static String _getWeekKey(DateTime date) {
    final weekStart = _getWeekStart(date);
    final weekNumber = _getWeekNumber(weekStart);
    return '${weekStart.year}-${weekNumber.toString().padLeft(2, '0')}';
  }

  // Helper: Get start of week (Monday)
  static DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
  }

  // Helper: Get week number in year
  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}

// Weekly mileage data
class WeeklyData {
  final DateTime weekStart;
  double distance; // km
  int duration; // seconds
  int runs;

  WeeklyData({
    required this.weekStart,
    required this.distance,
    required this.duration,
    required this.runs,
  });

  String get weekLabel {
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][weekStart.month - 1];
    return '$month ${weekStart.day}';
  }
}

// Pace trend data
class PaceTrend {
  final DateTime date;
  final double avgPaceMinPerKm;
  final int runCount;

  PaceTrend({
    required this.date,
    required this.avgPaceMinPerKm,
    required this.runCount,
  });

  String get monthLabel {
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][date.month - 1];
    return '$month ${date.year}';
  }
}

// Personal bests
class PersonalBests {
  final RunSession? fastest5k;
  final RunSession? fastest10k;
  final RunSession? fastestHalfMarathon;
  final RunSession? longestRun;
  final RunSession? fastestPaceRun;

  PersonalBests({
    this.fastest5k,
    this.fastest10k,
    this.fastestHalfMarathon,
    this.longestRun,
    this.fastestPaceRun,
  });
}

// Training load data
class TrainingLoad {
  final DateTime weekStart;
  double load; // composite metric
  double distance; // km
  int duration; // seconds

  TrainingLoad({
    required this.weekStart,
    required this.load,
    required this.distance,
    required this.duration,
  });

  String get weekLabel {
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][weekStart.month - 1];
    return '$month ${weekStart.day}';
  }
}
