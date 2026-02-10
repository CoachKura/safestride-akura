import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kura_coach_service.dart';

/// Kura Coach Adaptive Training System
/// Analyzes athlete data and creates personalized 4-week plans
/// After week 4, adapts based on performance
class KuraCoachAdaptiveService {
  static final _supabase = Supabase.instance.client;

  /// PHASE 1: Analyze Athlete's Current State
  /// Inputs: Evaluation form + Goals + Strava history
  static Future<Map<String, dynamic>> analyzeAthleteState(String userId) async {
    print('📊 Analyzing athlete state for user: $userId');

    // 1. Get athlete profile and latest AISRI assessment
    final profileData = await _supabase
        .from('athlete_profiles')
        .select('*, aisri_assessments(*)')
        .eq('user_id', userId)
        .single();

    // 2. Get athlete goals
    final goalsData = await _supabase
        .from('athlete_goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // 3. Get Strava activities (last 3 weeks)
    final threeWeeksAgo = DateTime.now().subtract(Duration(days: 21));
    final stravaData = await _supabase
        .from('strava_activities')
        .select()
        .eq('user_id', userId)
        .gte('activity_date', threeWeeksAgo.toIso8601String())
        .order('activity_date', ascending: false);

    // 4. Calculate AISRI score
    final aisriScore = await KuraCoachService.calculateAISRIScore(userId);
    final allowedZones = KuraCoachService.getAllowedZones(aisriScore);
    final safetyGates = await KuraCoachService.checkSafetyGates(userId);

    // 5. Analyze Strava training load
    final trainingAnalysis = _analyzeTrainingLoad(stravaData);

    // 6. Determine starting training phase
    final trainingPhase = _determineTrainingPhase(
      aisriScore: aisriScore,
      trainingLoad: trainingAnalysis,
      goals: goalsData,
    );

    return {
      'user_id': userId,
      'athlete_name': profileData['full_name'] ?? 'Athlete',
      'aisri_score': aisriScore,
      'allowed_zones': allowedZones,
      'safety_gates': safetyGates,
      'training_analysis': trainingAnalysis,
      'training_phase': trainingPhase,
      'goals': goalsData,
      'profile': profileData,
      'ready_for_plan': true,
    };
  }

  /// PHASE 2: Generate Initial 4-Week Training Plan
  static Future<String> generateInitial4WeekPlan({
    required String userId,
    required Map<String, dynamic> athleteState,
  }) async {
    print('🎯 Generating 4-week plan for ${athleteState['athlete_name']}');

    final trainingPhase = athleteState['training_phase'];
    final aisriScore = athleteState['aisri_score'];
    final goals = athleteState['goals'];

    // Create plan name
    final targetEvent = goals?['target_event'] ?? 'General Fitness';
    final planName = 'Kura Coach: 4-Week $trainingPhase - $targetEvent';

    // Generate weekly schedule
    final weeklySchedule = await KuraCoachService.generateWeeklySchedule(
      userId: userId,
      trainingPhase: trainingPhase,
      weekNumber: 1,
    );

    // Save plan to database
    final planId = await KuraCoachService.saveWorkoutPlan(
      userId: userId,
      planName: planName,
      trainingPhase: trainingPhase,
      weeklySchedule: weeklySchedule,
      startDate: DateTime.now(),
      durationWeeks: 4,
    );

    // Add plan metadata
    await _supabase
        .from('ai_workout_plans')
        .update({
          'aisri_score_at_creation': aisriScore,
          'metadata': {
            'weekly_schedule': weeklySchedule,
            'athlete_state': athleteState,
            'adaptation_enabled': true,
            'adaptation_after_week': 4,
          },
        })
        .eq('id', planId);

    print('✅ Plan created: $planId');
    return planId;
  }

  /// PHASE 3: Track Performance During 4 Weeks
  static Future<void> trackWeeklyPerformance({
    required String userId,
    required String planId,
    required int weekNumber,
  }) async {
    print('📈 Tracking week $weekNumber performance');

    final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));

    // Get completed workouts this week
    final workouts = await _supabase
        .from('ai_workouts')
        .select('*, workout_performance(*)')
        .eq('user_id', userId)
        .eq('plan_id', planId)
        .gte('workout_date', weekStart.toIso8601String())
        .lte('workout_date', weekEnd.toIso8601String());

    final completedWorkouts = workouts.where((w) => w['status'] == 'completed').toList();
    final scheduledCount = workouts.length;
    final completedCount = completedWorkouts.length;

    // Calculate metrics
    int totalTimeMinutes = 0;
    double totalDistance = 0;
    Map<String, int> zonesTime = {};

    for (var workout in completedWorkouts) {
      totalTimeMinutes += (workout['actual_duration_minutes'] ?? 0) as int;
      totalDistance += ((workout['actual_distance'] ?? 0) as num).toDouble();
      
      final zone = workout['zone'];
      zonesTime[zone] = (zonesTime[zone] ?? 0) + (workout['actual_duration_minutes'] ?? 0) as int;
    }

    // Get AISRI scores
    final currentAisri = await KuraCoachService.calculateAISRIScore(userId);
    
    // Save to training history
    await _supabase.from('aisri_training_history').insert({
      'user_id': userId,
      'week_start_date': weekStart.toIso8601String(),
      'week_end_date': weekEnd.toIso8601String(),
      'aisri_score_end': currentAisri,
      'workouts_completed': completedCount,
      'workouts_scheduled': scheduledCount,
      'total_time_minutes': totalTimeMinutes,
      'total_distance': totalDistance,
      'zones_trained': zonesTime,
      'progression_notes': 'Week $weekNumber: $completedCount/$scheduledCount workouts completed',
    });

    print('✅ Week $weekNumber tracked: $completedCount/$scheduledCount workouts');
  }

  /// PHASE 4: After Week 4 - Decide Next Training Plan
  static Future<String> adaptTrainingPlan({
    required String userId,
    required String previousPlanId,
  }) async {
    print('🔄 Adapting training plan after 4 weeks');

    // 1. Analyze performance from past 4 weeks
    final performanceAnalysis = await _analyzePerformanceTrend(userId, previousPlanId);

    // 2. Calculate current AISRI and compare to baseline
    final currentAisri = await KuraCoachService.calculateAISRIScore(userId);
    final previousPlan = await _supabase
        .from('ai_workout_plans')
        .select()
        .eq('id', previousPlanId)
        .single();
    
    final baselineAisri = previousPlan['aisri_score_at_creation'];
    final aisriChange = currentAisri - baselineAisri;

    // 3. Determine progression strategy
    final adaptation = _calculateAdaptation(
      performanceAnalysis: performanceAnalysis,
      aisriChange: aisriChange,
      currentAisri: currentAisri,
    );

    // 4. Select next training phase
    final nextPhase = _selectNextPhase(
      currentPhase: previousPlan['training_phase'],
      adaptation: adaptation,
      performanceAnalysis: performanceAnalysis,
    );

    // 5. Generate new 4-week plan
    final athleteState = await analyzeAthleteState(userId);
    athleteState['training_phase'] = nextPhase;
    athleteState['adaptation_data'] = adaptation;

    final newPlanId = await generateInitial4WeekPlan(
      userId: userId,
      athleteState: athleteState,
    );

    // 6. Mark previous plan as completed
    await _supabase
        .from('ai_workout_plans')
        .update({'status': 'completed'})
        .eq('id', previousPlanId);

    print('✅ New plan generated: $newPlanId with phase: $nextPhase');
    return newPlanId;
  }

  /// EXECUTION: Generate Plans for 10 Athletes
  static Future<List<Map<String, dynamic>>> generatePlansFor10Athletes() async {
    print('🚀 Starting plan generation for 10 athletes');

    // Get 10 athletes with recent evaluations
    final athletes = await _supabase
        .from('athlete_profiles')
        .select('user_id, full_name, aisri_assessments!inner(*)')
        .order('aisri_assessments.created_at', ascending: false)
        .limit(10);

    List<Map<String, dynamic>> results = [];

    for (var athlete in athletes) {
      try {
        final userId = athlete['user_id'];
        print('\n👤 Processing: ${athlete['full_name']}');

        // Phase 1: Analyze
        final athleteState = await analyzeAthleteState(userId);
        
        // Phase 2: Generate Plan
        final planId = await generateInitial4WeekPlan(
          userId: userId,
          athleteState: athleteState,
        );

        results.add({
          'user_id': userId,
          'name': athlete['full_name'],
          'plan_id': planId,
          'training_phase': athleteState['training_phase'],
          'aisri_score': athleteState['aisri_score'],
          'status': 'success',
        });

        print('✅ Plan created for ${athlete['full_name']}: $planId');
      } catch (e) {
        print('❌ Error for ${athlete['full_name']}: $e');
        results.add({
          'user_id': athlete['user_id'],
          'name': athlete['full_name'],
          'status': 'error',
          'error': e.toString(),
        });
      }
    }

    print('\n🎉 Batch generation complete: ${results.length} athletes processed');
    return results;
  }

  // ========== HELPER FUNCTIONS ==========

  static Map<String, dynamic> _analyzeTrainingLoad(List<dynamic> activities) {
    if (activities.isEmpty) {
      return {
        'weeks_trained': 0,
        'avg_weekly_time': 0,
        'avg_weekly_distance': 0,
        'consistency_score': 0,
        'training_level': 'beginner',
      };
    }

    int totalTime = 0;
    double totalDistance = 0;
    Map<int, int> weeklyCount = {};

    for (var activity in activities) {
      final duration = activity['moving_time'] ?? 0;
      final distance = ((activity['distance'] ?? 0) / 1000).toDouble(); // Convert to km
      
      totalTime += duration as int;
      totalDistance += distance;

      final date = DateTime.parse(activity['activity_date']);
      final weekNum = date.difference(DateTime.now().subtract(Duration(days: 21))).inDays ~/ 7;
      weeklyCount[weekNum] = (weeklyCount[weekNum] ?? 0) + 1;
    }

    final avgWeeklyTime = totalTime / 3;
    final avgWeeklyDistance = totalDistance / 3;
    final consistencyScore = (weeklyCount.length / 3 * 100).round();

    String trainingLevel;
    if (avgWeeklyTime < 60 * 60) { // Less than 1 hour/week
      trainingLevel = 'beginner';
    } else if (avgWeeklyTime < 180 * 60) { // Less than 3 hours/week
      trainingLevel = 'intermediate';
    } else {
      trainingLevel = 'advanced';
    }

    return {
      'weeks_trained': weeklyCount.length,
      'avg_weekly_time': (avgWeeklyTime / 60).round(), // minutes
      'avg_weekly_distance': avgWeeklyDistance.toStringAsFixed(1),
      'consistency_score': consistencyScore,
      'training_level': trainingLevel,
      'total_activities': activities.length,
    };
  }

  static String _determineTrainingPhase({
    required double aisriScore,
    required Map<String, dynamic> trainingLoad,
    required Map<String, dynamic>? goals,
  }) {
    final trainingLevel = trainingLoad['training_level'];
    final consistencyScore = trainingLoad['consistency_score'];

    // Beginners or low AISRI → Foundation
    if (aisriScore < 55 || trainingLevel == 'beginner' || consistencyScore < 50) {
      return 'Foundation';
    }

    // Check if preparing for an event
    if (goals != null && goals['target_event'] != null) {
      final targetDate = goals['target_date'] != null 
          ? DateTime.parse(goals['target_date'])
          : null;
      
      if (targetDate != null) {
        final weeksUntilEvent = targetDate.difference(DateTime.now()).inDays ~/ 7;
        
        if (weeksUntilEvent <= 4) {
          return 'Peak';
        } else if (weeksUntilEvent <= 8) {
          return 'Threshold';
        }
      }
    }

    // Intermediate → Endurance
    if (aisriScore >= 55 && aisriScore < 70) {
      return 'Endurance';
    }

    // Advanced → Threshold
    if (aisriScore >= 70 && aisriScore < 85) {
      return 'Threshold';
    }

    // Elite → Peak (if safety gates pass)
    return 'Peak';
  }

  static Future<Map<String, dynamic>> _analyzePerformanceTrend(
    String userId,
    String planId,
  ) async {
    final fourWeeksAgo = DateTime.now().subtract(Duration(days: 28));

    // Get all workouts from the plan
    final workouts = await _supabase
        .from('ai_workouts')
        .select('*, workout_performance(*)')
        .eq('user_id', userId)
        .eq('plan_id', planId)
        .gte('workout_date', fourWeeksAgo.toIso8601String())
        .order('workout_date', ascending: true);

    final completed = workouts.where((w) => w['status'] == 'completed').toList();
    final completionRate = completed.length / workouts.length;

    // Calculate weekly progression
    Map<int, Map<String, dynamic>> weeklyMetrics = {};
    for (var workout in completed) {
      final date = DateTime.parse(workout['workout_date']);
      final weekNum = date.difference(fourWeeksAgo).inDays ~/ 7 + 1;
      
      if (!weeklyMetrics.containsKey(weekNum)) {
        weeklyMetrics[weekNum] = {
          'count': 0,
          'total_time': 0,
          'total_distance': 0.0,
          'avg_perception': 0.0,
          'perception_count': 0,
        };
      }

      final week = weeklyMetrics[weekNum]!;
      week['count'] = week['count'] + 1;
      week['total_time'] = week['total_time'] + (workout['actual_duration_minutes'] ?? 0);
      week['total_distance'] = week['total_distance'] + ((workout['actual_distance'] ?? 0) as num).toDouble();
      
      final performance = workout['workout_performance'];
      if (performance != null && performance.isNotEmpty) {
        final perception = performance[0]['perception_rating'];
        if (perception != null) {
          week['avg_perception'] = week['avg_perception'] + perception;
          week['perception_count'] = week['perception_count'] + 1;
        }
      }
    }

    // Calculate averages
    for (var week in weeklyMetrics.values) {
      if (week['perception_count'] > 0) {
        week['avg_perception'] = week['avg_perception'] / week['perception_count'];
      }
    }

    // Determine trend
    bool improving = weeklyMetrics.length >= 3 &&
        weeklyMetrics[4]!['count'] >= weeklyMetrics[1]!['count'];

    return {
      'completion_rate': completionRate,
      'total_completed': completed.length,
      'total_scheduled': workouts.length,
      'weekly_metrics': weeklyMetrics,
      'trend': improving ? 'improving' : 'stable',
    };
  }

  static Map<String, dynamic> _calculateAdaptation({
    required Map<String, dynamic> performanceAnalysis,
    required double aisriChange,
    required double currentAisri,
  }) {
    final completionRate = performanceAnalysis['completion_rate'];
    final trend = performanceAnalysis['trend'];

    String recommendation;
    String intensity;

    if (completionRate > 0.85 && aisriChange >= 5 && trend == 'improving') {
      recommendation = 'progress'; // Move to harder phase
      intensity = 'increase';
    } else if (completionRate < 0.60 || aisriChange <= -5) {
      recommendation = 'reduce'; // Easier phase
      intensity = 'decrease';
    } else {
      recommendation = 'maintain'; // Stay in current phase
      intensity = 'maintain';
    }

    return {
      'recommendation': recommendation,
      'intensity': intensity,
      'aisri_change': aisriChange,
      'completion_rate': completionRate,
      'reasoning': '$trend performance with ${(completionRate * 100).round()}% completion',
    };
  }

  static String _selectNextPhase({
    required String currentPhase,
    required Map<String, dynamic> adaptation,
    required Map<String, dynamic> performanceAnalysis,
  }) {
    final recommendation = adaptation['recommendation'];

    final phaseProgression = ['Foundation', 'Endurance', 'Threshold', 'Peak'];
    final currentIndex = phaseProgression.indexOf(currentPhase);

    if (recommendation == 'progress' && currentIndex < phaseProgression.length - 1) {
      return phaseProgression[currentIndex + 1];
    } else if (recommendation == 'reduce' && currentIndex > 0) {
      return phaseProgression[currentIndex - 1];
    } else {
      return currentPhase; // Maintain
    }
  }
}
