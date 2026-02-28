// Real-Time Coaching Service
// Provides live feedback and coaching during runs

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/biomechanics_data.dart';
import '../models/run_session.dart';

enum CoachingPriority { low, medium, high, critical }

class CoachingFeedback {
  final String message;
  final CoachingPriority priority;
  final IconData icon;
  final Color color;
  final String? actionTip;
  final DateTime timestamp;

  CoachingFeedback({
    required this.message,
    required this.priority,
    required this.icon,
    required this.color,
    this.actionTip,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class RealtimeCoachingService {
  // Singleton pattern
  static final RealtimeCoachingService _instance =
      RealtimeCoachingService._internal();
  factory RealtimeCoachingService() => _instance;
  RealtimeCoachingService._internal();

  // Stream controller for coaching feedback
  final _feedbackController = StreamController<CoachingFeedback>.broadcast();
  Stream<CoachingFeedback> get feedbackStream => _feedbackController.stream;

  // Tracking state
  RunSession? _currentSession;
  BiomechanicsData? _lastBiomechanics;
  DateTime? _lastFeedbackTime;
  final Duration _feedbackCooldown = const Duration(seconds: 30);

  // Pace targets (min/km)
  double? _targetPaceMin;
  double? _targetPaceMax;

  // Start coaching for a session
  void startCoaching({
    required RunSession session,
    double? targetPaceMin,
    double? targetPaceMax,
  }) {
    _currentSession = session;
    _targetPaceMin = targetPaceMin;
    _targetPaceMax = targetPaceMax;
    _lastFeedbackTime = null;

    _sendFeedback(
      CoachingFeedback(
        message: 'Coaching started! I\'ll guide you through your run.',
        priority: CoachingPriority.low,
        icon: Icons.lightbulb_outline,
        color: Colors.blue,
      ),
    );
  }

  // Stop coaching
  void stopCoaching() {
    if (_currentSession != null) {
      _sendFeedback(
        CoachingFeedback(
          message: 'Great work! Run complete.',
          priority: CoachingPriority.low,
          icon: Icons.emoji_events,
          color: Colors.green,
        ),
      );
    }
    _currentSession = null;
    _lastBiomechanics = null;
    _lastFeedbackTime = null;
  }

  // Update with new session data
  void updateSession(RunSession session) {
    _currentSession = session;
    _analyzePace();
    _analyzeDistance();
  }

  // Update with new biomechanics data
  void updateBiomechanics(BiomechanicsData data) {
    _lastBiomechanics = data;
    _analyzeBiomechanics();
  }

  // Analyze pace vs target
  void _analyzePace() {
    if (_currentSession == null) return;
    if (_currentSession!.currentPaceMinPerKm == null) return;
    if (_targetPaceMin == null || _targetPaceMax == null) return;

    // Check if enough time has passed since last feedback
    if (!_canSendFeedback()) return;

    final currentPace = _currentSession!.currentPaceMinPerKm!;

    if (currentPace < _targetPaceMin!) {
      // Running too fast
      final diff = _targetPaceMin! - currentPace;
      if (diff > 0.5) {
        _sendFeedback(
          CoachingFeedback(
            message: '⚡ Slow down! You\'re running too fast.',
            priority: CoachingPriority.high,
            icon: Icons.speed,
            color: Colors.orange,
            actionTip:
                'Current: ${_formatPace(currentPace)}, Target: ${_formatPace(_targetPaceMin!)}',
          ),
        );
      }
    } else if (currentPace > _targetPaceMax!) {
      // Running too slow
      final diff = currentPace - _targetPaceMax!;
      if (diff > 0.5) {
        _sendFeedback(
          CoachingFeedback(
            message: '🐌 Speed up a bit! You\'re running too slow.',
            priority: CoachingPriority.medium,
            icon: Icons.trending_up,
            color: Colors.blue,
            actionTip:
                'Current: ${_formatPace(currentPace)}, Target: ${_formatPace(_targetPaceMax!)}',
          ),
        );
      }
    } else {
      // Perfect pace zone
      if (_shouldSendPositiveFeedback()) {
        _sendFeedback(
          CoachingFeedback(
            message: '✅ Perfect pace! Keep it up.',
            priority: CoachingPriority.low,
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        );
      }
    }
  }

  // Analyze distance milestones
  void _analyzeDistance() {
    if (_currentSession == null) return;

    final distanceKm = _currentSession!.distanceMeters / 1000;
    final plannedKm = _currentSession!.plannedDistanceKm;

    // Check milestone achievements
    if (distanceKm >= 1 && distanceKm < 1.1) {
      _sendFeedback(
        CoachingFeedback(
          message: '🎯 1 km complete!',
          priority: CoachingPriority.low,
          icon: Icons.flag,
          color: Colors.purple,
        ),
      );
    } else if (distanceKm >= 5 && distanceKm < 5.1) {
      _sendFeedback(
        CoachingFeedback(
          message: '🎯 5 km complete! Great job!',
          priority: CoachingPriority.low,
          icon: Icons.flag,
          color: Colors.purple,
        ),
      );
    } else if (plannedKm != null && distanceKm >= plannedKm * 0.9) {
      _sendFeedback(
        CoachingFeedback(
          message: '🏁 Final stretch! You\'re almost there!',
          priority: CoachingPriority.medium,
          icon: Icons.emoji_events,
          color: Colors.amber,
        ),
      );
    }
  }

  // Analyze biomechanics
  void _analyzeBiomechanics() {
    if (_lastBiomechanics == null) return;
    if (!_canSendFeedback()) return;

    final bio = _lastBiomechanics!;

    // Check cadence
    if (bio.cadence != null) {
      if (bio.cadence! < 160) {
        _sendFeedback(
          CoachingFeedback(
            message: '🦶 Increase cadence: Take quicker steps.',
            priority: CoachingPriority.medium,
            icon: Icons.directions_run,
            color: Colors.orange,
            actionTip: 'Current: ${bio.cadence} spm, Target: 170-180 spm',
          ),
        );
      } else if (bio.cadence! > 190) {
        _sendFeedback(
          CoachingFeedback(
            message: '🦶 Reduce cadence: Your steps are too quick.',
            priority: CoachingPriority.low,
            icon: Icons.directions_run,
            color: Colors.blue,
            actionTip: 'Current: ${bio.cadence} spm, Target: 170-180 spm',
          ),
        );
      }
    }

    // Check ground contact time
    if (bio.groundContactTime != null && bio.groundContactTime! > 300) {
      _sendFeedback(
        CoachingFeedback(
          message: '⚡ Quick feet! Push off faster.',
          priority: CoachingPriority.medium,
          icon: Icons.speed,
          color: Colors.orange,
          actionTip:
              'Ground contact: ${bio.groundContactTime}ms (aim for <250ms)',
        ),
      );
    }

    // Check vertical oscillation
    if (bio.verticalOscillation != null && bio.verticalOscillation! > 12) {
      _sendFeedback(
        CoachingFeedback(
          message: '📏 Reduce bounce: Run forward, not up.',
          priority: CoachingPriority.low,
          icon: Icons.height,
          color: Colors.blue,
          actionTip:
              'Vertical oscillation: ${bio.verticalOscillation!.toStringAsFixed(1)} cm (aim for <10cm)',
        ),
      );
    }

    // Check asymmetry
    final strideAsym = bio.strideAsymmetry;
    if (strideAsym != null && strideAsym > 10) {
      _sendFeedback(
        CoachingFeedback(
          message: '⚠️ Stride imbalance detected!',
          priority: CoachingPriority.high,
          icon: Icons.warning,
          color: Colors.red,
          actionTip:
              'Asymmetry: ${strideAsym.toStringAsFixed(1)}% - Focus on even strides',
        ),
      );
    }

    // Check impact forces
    if (bio.impactForce != null && bio.impactForce! > 3.0) {
      _sendFeedback(
        CoachingFeedback(
          message: '🛡️ Softer landings! Reduce impact.',
          priority: CoachingPriority.high,
          icon: Icons.shield,
          color: Colors.red,
          actionTip:
              'Impact: ${bio.impactForce!.toStringAsFixed(1)}G - Land midfoot',
        ),
      );
    }
  }

  // Provide motivational feedback
  void sendMotivation({required String type}) {
    switch (type) {
      case 'halfway':
        _sendFeedback(
          CoachingFeedback(
            message: '🎉 Halfway there! You\'re doing great!',
            priority: CoachingPriority.low,
            icon: Icons.celebration,
            color: Colors.green,
          ),
        );
        break;
      case 'struggling':
        _sendFeedback(
          CoachingFeedback(
            message: '💪 You\'ve got this! Stay strong!',
            priority: CoachingPriority.medium,
            icon: Icons.psychology,
            color: Colors.amber,
          ),
        );
        break;
      case 'final_push':
        _sendFeedback(
          CoachingFeedback(
            message: '🔥 Final push! Give it everything!',
            priority: CoachingPriority.high,
            icon: Icons.local_fire_department,
            color: Colors.deepOrange,
          ),
        );
        break;
    }
  }

  // Helper: Check if we can send feedback (cooldown)
  bool _canSendFeedback() {
    if (_lastFeedbackTime == null) return true;
    return DateTime.now().difference(_lastFeedbackTime!) > _feedbackCooldown;
  }

  // Helper: Should send positive feedback (random, not too often)
  bool _shouldSendPositiveFeedback() {
    return false; // Disabled for now - can be enhanced with actual random logic
  }

  // Helper: Send feedback through stream
  void _sendFeedback(CoachingFeedback feedback) {
    _lastFeedbackTime = DateTime.now();
    _feedbackController.add(feedback);
  }

  // Helper: Format pace
  String _formatPace(double paceMinPerKm) {
    final minutes = paceMinPerKm.floor();
    final seconds = ((paceMinPerKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
  }

  // Dispose
  void dispose() {
    _feedbackController.close();
  }
}

// Pre-defined coaching messages for different scenarios
class CoachingMessages {
  static const warmup = [
    'Start easy and warm up gradually',
    'First km should feel comfortable',
    'Focus on relaxed breathing',
  ];

  static const tempo = [
    'Comfortably hard pace - you should be able to speak short sentences',
    'Maintain steady effort throughout',
    'Focus on strong, controlled breathing',
  ];

  static const interval = [
    'Push hard during work intervals',
    'Use recovery periods to catch your breath',
    'Maintain good form even when tired',
  ];

  static const longRun = [
    'Keep it conversational - you should be able to hold a conversation',
    'Stay relaxed and conserve energy',
    'Focus on consistent, easy pace',
  ];

  static const recovery = [
    'Very easy pace - this is active recovery',
    'No pressure, just enjoy the run',
    'Listen to your body',
  ];

  static const form = [
    'Keep your shoulders relaxed',
    'Arms at 90 degrees, swing from shoulders',
    'Look ahead, not down',
    'Land midfoot underneath your body',
    'Keep your core engaged',
    'Posture upright, slight forward lean from ankles',
  ];
}
