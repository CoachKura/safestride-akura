// lib/models/athlete_goal.dart

class AthleteGoal {
  final String id;
  final String userId;
  
  // Goal Details
  final String goalType;
  final String goalTitle;
  final String? goalDescription;
  
  // Target Specifications
  final double? targetDistanceKm;
  final int? targetTimeMinutes;
  final double? targetPaceMinPerKm;
  final double? targetWeightKg;
  final int? targetAisriScore;
  final int? targetWorkoutsPerWeek;
  final String? customMetricName;
  final double? customMetricTarget;
  
  // Timeline
  final DateTime startDate;
  final DateTime targetDate;
  final DateTime? actualCompletionDate;
  
  // Progress
  final String status;
  final int progressPercentage;
  final double? currentValue;
  
  // Milestones
  final bool milestone25Achieved;
  final DateTime? milestone25Date;
  final bool milestone50Achieved;
  final DateTime? milestone50Date;
  final bool milestone75Achieved;
  final DateTime? milestone75Date;
  final bool milestone100Achieved;
  final DateTime? milestone100Date;
  
  // Motivation & Tracking
  final String priority;
  final String? motivationReason;
  final String? reward;
  
  // Related Items
  final String? relatedTrainingProtocolId;
  final String? relatedRaceEvent;
  final DateTime? raceDate;
  
  // Social Sharing
  final bool isPublic;
  final bool sharedWithCoach;
  
  // Notes & Reflection
  final String? notes;
  final String? completionReflection;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  AthleteGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.goalTitle,
    this.goalDescription,
    this.targetDistanceKm,
    this.targetTimeMinutes,
    this.targetPaceMinPerKm,
    this.targetWeightKg,
    this.targetAisriScore,
    this.targetWorkoutsPerWeek,
    this.customMetricName,
    this.customMetricTarget,
    required this.startDate,
    required this.targetDate,
    this.actualCompletionDate,
    this.status = 'active',
    this.progressPercentage = 0,
    this.currentValue,
    this.milestone25Achieved = false,
    this.milestone25Date,
    this.milestone50Achieved = false,
    this.milestone50Date,
    this.milestone75Achieved = false,
    this.milestone75Date,
    this.milestone100Achieved = false,
    this.milestone100Date,
    this.priority = 'medium',
    this.motivationReason,
    this.reward,
    this.relatedTrainingProtocolId,
    this.relatedRaceEvent,
    this.raceDate,
    this.isPublic = false,
    this.sharedWithCoach = true,
    this.notes,
    this.completionReflection,
    required this.createdAt,
    this.updatedAt,
  });

  // Helper getters
  int get daysUntilTarget {
    if (status == 'completed') return 0;
    final days = targetDate.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }

  int get totalDays {
    return targetDate.difference(startDate).inDays;
  }

  int get daysElapsed {
    final elapsed = DateTime.now().difference(startDate).inDays;
    return elapsed < 0 ? 0 : (elapsed > totalDays ? totalDays : elapsed);
  }

  double get timeProgressPercentage {
    if (totalDays == 0) return 0;
    return (daysElapsed / totalDays * 100).clamp(0, 100);
  }

  bool get isOverdue => 
    targetDate.isBefore(DateTime.now()) && 
    status == 'active';

  String get goalTypeDisplay {
    switch (goalType) {
      case 'complete_distance':
        return 'Complete Distance';
      case 'time_target':
        return 'Time Target';
      case 'consistency':
        return 'Consistency';
      case 'injury_prevention':
        return 'Injury Prevention';
      case 'weight_loss':
        return 'Weight Loss';
      case 'strength_gain':
        return 'Strength Gain';
      case 'flexibility':
        return 'Flexibility';
      case 'aisri_score':
        return 'AISRI Score';
      case 'custom':
        return 'Custom Goal';
      default:
        return goalType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'paused':
        return 'Paused';
      case 'abandoned':
        return 'Abandoned';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'active':
        return '#2196F3';
      case 'completed':
        return '#4CAF50';
      case 'failed':
        return '#F44336';
      case 'paused':
        return '#FF9800';
      case 'abandoned':
        return '#9E9E9E';
      default:
        return '#9E9E9E';
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return priority;
    }
  }

  String get priorityColor {
    switch (priority) {
      case 'low':
        return '#4CAF50';
      case 'medium':
        return '#2196F3';
      case 'high':
        return '#FF9800';
      case 'critical':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  String get targetDisplay {
    switch (goalType) {
      case 'complete_distance':
        return '${targetDistanceKm?.toStringAsFixed(1)} km';
      case 'time_target':
        final hours = (targetTimeMinutes ?? 0) ~/ 60;
        final mins = (targetTimeMinutes ?? 0) % 60;
        return '${hours}h ${mins}m';
      case 'weight_loss':
        return '${targetWeightKg?.toStringAsFixed(1)} kg';
      case 'aisri_score':
        return targetAisriScore.toString();
      case 'consistency':
        return '$targetWorkoutsPerWeek workouts/week';
      case 'custom':
        return '${customMetricTarget?.toStringAsFixed(1)} $customMetricName';
      default:
        return 'N/A';
    }
  }

  int get nextMilestone {
    if (!milestone25Achieved) return 25;
    if (!milestone50Achieved) return 50;
    if (!milestone75Achieved) return 75;
    if (!milestone100Achieved) return 100;
    return 100;
  }

  // Supabase JSON serialization
  factory AthleteGoal.fromJson(Map<String, dynamic> json) {
    return AthleteGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalType: json['goal_type'] as String,
      goalTitle: json['goal_title'] as String,
      goalDescription: json['goal_description'] as String?,
      targetDistanceKm: json['target_distance_km'] != null
          ? (json['target_distance_km'] as num).toDouble()
          : null,
      targetTimeMinutes: json['target_time_minutes'] as int?,
      targetPaceMinPerKm: json['target_pace_min_per_km'] != null
          ? (json['target_pace_min_per_km'] as num).toDouble()
          : null,
      targetWeightKg: json['target_weight_kg'] != null
          ? (json['target_weight_kg'] as num).toDouble()
          : null,
      targetAisriScore: json['target_aisri_score'] as int?,
      targetWorkoutsPerWeek: json['target_workouts_per_week'] as int?,
      customMetricName: json['custom_metric_name'] as String?,
      customMetricTarget: json['custom_metric_target'] != null
          ? (json['custom_metric_target'] as num).toDouble()
          : null,
      startDate: DateTime.parse(json['start_date'] as String),
      targetDate: DateTime.parse(json['target_date'] as String),
      actualCompletionDate: json['actual_completion_date'] != null
          ? DateTime.parse(json['actual_completion_date'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      progressPercentage: json['progress_percentage'] as int? ?? 0,
      currentValue: json['current_value'] != null
          ? (json['current_value'] as num).toDouble()
          : null,
      milestone25Achieved: json['milestone_25_achieved'] as bool? ?? false,
      milestone25Date: json['milestone_25_date'] != null
          ? DateTime.parse(json['milestone_25_date'] as String)
          : null,
      milestone50Achieved: json['milestone_50_achieved'] as bool? ?? false,
      milestone50Date: json['milestone_50_date'] != null
          ? DateTime.parse(json['milestone_50_date'] as String)
          : null,
      milestone75Achieved: json['milestone_75_achieved'] as bool? ?? false,
      milestone75Date: json['milestone_75_date'] != null
          ? DateTime.parse(json['milestone_75_date'] as String)
          : null,
      milestone100Achieved: json['milestone_100_achieved'] as bool? ?? false,
      milestone100Date: json['milestone_100_date'] != null
          ? DateTime.parse(json['milestone_100_date'] as String)
          : null,
      priority: json['priority'] as String? ?? 'medium',
      motivationReason: json['motivation_reason'] as String?,
      reward: json['reward'] as String?,
      relatedTrainingProtocolId: json['related_training_protocol_id'] as String?,
      relatedRaceEvent: json['related_race_event'] as String?,
      raceDate: json['race_date'] != null
          ? DateTime.parse(json['race_date'] as String)
          : null,
      isPublic: json['is_public'] as bool? ?? false,
      sharedWithCoach: json['shared_with_coach'] as bool? ?? true,
      notes: json['notes'] as String?,
      completionReflection: json['completion_reflection'] as String?,
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
      'goal_type': goalType,
      'goal_title': goalTitle,
      'goal_description': goalDescription,
      'target_distance_km': targetDistanceKm,
      'target_time_minutes': targetTimeMinutes,
      'target_pace_min_per_km': targetPaceMinPerKm,
      'target_weight_kg': targetWeightKg,
      'target_aisri_score': targetAisriScore,
      'target_workouts_per_week': targetWorkoutsPerWeek,
      'custom_metric_name': customMetricName,
      'custom_metric_target': customMetricTarget,
      'start_date': startDate.toIso8601String().split('T')[0],
      'target_date': targetDate.toIso8601String().split('T')[0],
      'actual_completion_date': actualCompletionDate?.toIso8601String().split('T')[0],
      'status': status,
      'progress_percentage': progressPercentage,
      'current_value': currentValue,
      'priority': priority,
      'motivation_reason': motivationReason,
      'reward': reward,
      'related_training_protocol_id': relatedTrainingProtocolId,
      'related_race_event': relatedRaceEvent,
      'race_date': raceDate?.toIso8601String().split('T')[0],
      'is_public': isPublic,
      'shared_with_coach': sharedWithCoach,
      'notes': notes,
      'completion_reflection': completionReflection,
    };
  }

  AthleteGoal copyWith({
    String? status,
    int? progressPercentage,
    double? currentValue,
    DateTime? actualCompletionDate,
    String? notes,
    String? completionReflection,
  }) {
    return AthleteGoal(
      id: id,
      userId: userId,
      goalType: goalType,
      goalTitle: goalTitle,
      goalDescription: goalDescription,
      targetDistanceKm: targetDistanceKm,
      targetTimeMinutes: targetTimeMinutes,
      targetPaceMinPerKm: targetPaceMinPerKm,
      targetWeightKg: targetWeightKg,
      targetAisriScore: targetAisriScore,
      targetWorkoutsPerWeek: targetWorkoutsPerWeek,
      customMetricName: customMetricName,
      customMetricTarget: customMetricTarget,
      startDate: startDate,
      targetDate: targetDate,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      currentValue: currentValue ?? this.currentValue,
      milestone25Achieved: milestone25Achieved,
      milestone25Date: milestone25Date,
      milestone50Achieved: milestone50Achieved,
      milestone50Date: milestone50Date,
      milestone75Achieved: milestone75Achieved,
      milestone75Date: milestone75Date,
      milestone100Achieved: milestone100Achieved,
      milestone100Date: milestone100Date,
      priority: priority,
      motivationReason: motivationReason,
      reward: reward,
      relatedTrainingProtocolId: relatedTrainingProtocolId,
      relatedRaceEvent: relatedRaceEvent,
      raceDate: raceDate,
      isPublic: isPublic,
      sharedWithCoach: sharedWithCoach,
      notes: notes ?? this.notes,
      completionReflection: completionReflection ?? this.completionReflection,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
