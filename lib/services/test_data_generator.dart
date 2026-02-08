// Test Data Generator for Post-Assessment System
//
// Provides mock assessment data for testing all screens and features
// without needing to complete the full evaluation form

import '../services/gait_pathology_analyzer.dart';
import '../services/assessment_report_generator.dart';
import 'dart:developer' as developer;

class TestDataGenerator {
  /// Generate a complete assessment dataset with severe issues
  /// (for testing worst-case scenarios)
  static Map<String, dynamic> generateSevereAssessment() {
    return {
      'user_id': 'test-user-001',
      'ankle_dorsiflexion_cm': 6.0, // Poor (normal: >10cm)
      'hip_flexion_angle': 85, // Poor (normal: >90)
      'hip_abduction_reps': 12, // Weak (normal: >20)
      'hip_extension_reps': 15, // Moderate
      'single_leg_bridge_reps': 8, // Weak (normal: >15)
      'balance_test_seconds': 10, // Poor (normal: >15)
      'standing_knee_flexion_angle': 110, // Moderate
      'standing_hip_extension_angle': 8, // Poor (normal: >15)
      'toe_touch_distance_cm': -15.0, // Tight hamstrings
      'plank_hold_seconds': 25, // Poor (normal: >60)
      'side_plank_hold_seconds': 15, // Weak
      'standing_quad_stretch_angle': 100, // Tight quads
      'standing_hip_flexor_stretch_angle': 8, // Tight hip flexors
      'internal_hip_rotation_angle': 25, // Limited
      'external_hip_rotation_angle': 30, // Limited
      'previous_injuries':
          'IT band syndrome (2024), Runner\'s knee (2023), Shin splints (2022)',
      'current_pain': 'Mild lateral knee pain during long runs',
      'weekly_mileage': 35.0,
      'goals': 'Complete half marathon without injury',
      'running_duration_minutes': 45,
      'perceived_exertion': 7,
    };
  }

  /// Generate a healthy assessment dataset
  /// (for testing optimal scenarios)
  static Map<String, dynamic> generateHealthyAssessment() {
    return {
      'user_id': 'test-user-002',
      'ankle_dorsiflexion_cm': 12.5,
      'hip_flexion_angle': 95,
      'hip_abduction_reps': 25,
      'hip_extension_reps': 25,
      'single_leg_bridge_reps': 20,
      'balance_test_seconds': 30,
      'standing_knee_flexion_angle': 135,
      'standing_hip_extension_angle': 18,
      'toe_touch_distance_cm': 0.0,
      'plank_hold_seconds': 90,
      'side_plank_hold_seconds': 60,
      'standing_quad_stretch_angle': 135,
      'standing_hip_flexor_stretch_angle': 18,
      'internal_hip_rotation_angle': 45,
      'external_hip_rotation_angle': 50,
      'previous_injuries': 'None',
      'current_pain': 'None',
      'weekly_mileage': 40.0,
      'goals': 'Maintain fitness and prevent injuries',
      'running_duration_minutes': 60,
      'perceived_exertion': 5,
    };
  }

  /// Generate a moderate risk assessment
  /// (for testing typical scenarios)
  static Map<String, dynamic> generateModerateAssessment() {
    return {
      'user_id': 'test-user-003',
      'ankle_dorsiflexion_cm': 9.0,
      'hip_flexion_angle': 88,
      'hip_abduction_reps': 18,
      'hip_extension_reps': 20,
      'single_leg_bridge_reps': 12,
      'balance_test_seconds': 15,
      'standing_knee_flexion_angle': 125,
      'standing_hip_extension_angle': 12,
      'toe_touch_distance_cm': -8.0,
      'plank_hold_seconds': 45,
      'side_plank_hold_seconds': 30,
      'standing_quad_stretch_angle': 120,
      'standing_hip_flexor_stretch_angle': 12,
      'internal_hip_rotation_angle': 35,
      'external_hip_rotation_angle': 40,
      'previous_injuries': 'Plantar fasciitis (2023)',
      'current_pain': 'Occasional foot soreness',
      'weekly_mileage': 25.0,
      'goals': 'Train for 10K race',
      'running_duration_minutes': 40,
      'perceived_exertion': 6,
    };
  }

  /// Generate realistic AISRI scores based on assessment data
  static Map<String, int> calculateMockPillarScores(
      Map<String, dynamic> assessment) {
    // This is a simplified version - the real calculator uses the full AISRI algorithm
    int ankleDorsi =
        assessment['ankle_dorsiflexion_cm'] as double > 10 ? 80 : 50;
    int hipStrength = assessment['hip_abduction_reps'] as int > 20 ? 85 : 55;
    int core = assessment['plank_hold_seconds'] as int > 60 ? 85 : 60;

    return {
      'Adaptability': ankleDorsi,
      'Injury Risk': hipStrength,
      'Fatigue Management': core,
      'Recovery Capacity': 70,
      'Training Intensity': 75,
      'Consistency': 80,
    };
  }

  /// Calculate overall AISRI score from pillar scores
  static int calculateAISTRIScore(Map<String, int> pillarScores) {
    int total = pillarScores.values.reduce((a, b) => a + b);
    return (total / pillarScores.length).round();
  }

  /// Generate a complete test report with all components
  static AssessmentReport generateTestReport({
    required Map<String, dynamic> assessmentData,
    required int aistriScore,
    required Map<String, int> pillarScores,
  }) {
    // Analyze gait pathologies
    final gaitPathologies =
        GaitPathologyAnalyzer.analyzeGaitPatterns(assessmentData);

    // Generate full report
    return AssessmentReportGenerator.generateReport(
      athleteId: assessmentData['user_id'],
      assessmentData: assessmentData,
      aistriScore: aistriScore,
      pillarScores: pillarScores,
      injuryRisks: [], // Mock empty for now
      gaitPathologies: gaitPathologies,
    );
  }

  /// Quick test data sets for different scenarios
  static const Map<String, Map<String, dynamic>> testScenarios = {
    'severe': {
      'description': 'Multiple severe issues requiring 16-week recovery',
      'expectedPathologies': ['Bow Legs', 'Overpronation'],
      'expectedAISTRI': 45,
    },
    'healthy': {
      'description': 'Optimal fitness with minimal risk',
      'expectedPathologies': [],
      'expectedAISTRI': 85,
    },
    'moderate': {
      'description': 'Typical recreational runner with some weaknesses',
      'expectedPathologies': ['Knock Knees'],
      'expectedAISTRI': 65,
    },
  };
}

// Extension methods for easy testing
extension TestDataHelpers on Map<String, dynamic> {
  /// Print a formatted summary of assessment data
  void printSummary() {
    developer.log('\n═══════════════════════════════════════');
    developer.log('ASSESSMENT DATA SUMMARY');
    developer.log('═══════════════════════════════════════');
    developer.log('User ID: ${this['user_id']}');
    developer.log('');
    developer.log('ROM TESTS:');
    developer.log('  Ankle Dorsiflexion: ${this['ankle_dorsiflexion_cm']}cm');
    developer.log('  Hip Flexion: ${this['hip_flexion_angle']}°');
    developer.log('  Toe Touch: ${this['toe_touch_distance_cm']}cm');
    developer.log('');
    developer.log('STRENGTH TESTS:');
    developer.log('  Hip Abduction: ${this['hip_abduction_reps']} reps');
    developer.log('  Hip Extension: ${this['hip_extension_reps']} reps');
    developer
        .log('  Single Leg Bridge: ${this['single_leg_bridge_reps']} reps');
    developer.log('  Balance: ${this['balance_test_seconds']} seconds');
    developer.log('  Plank: ${this['plank_hold_seconds']} seconds');
    developer.log('  Side Plank: ${this['side_plank_hold_seconds']} seconds');
    developer.log('');
    developer.log('HISTORY:');
    developer.log('  Previous Injuries: ${this['previous_injuries']}');
    developer.log('  Current Pain: ${this['current_pain']}');
    developer.log('  Weekly Mileage: ${this['weekly_mileage']}km');
    developer.log('═══════════════════════════════════════\n');
  }
}

// Example usage in tests:
//
// ```dart
// // Generate test data
// final severeData = TestDataGenerator.generateSevereAssessment();
// final pillarScores = TestDataGenerator.calculateMockPillarScores(severeData);
// final aistriScore = TestDataGenerator.calculateAISTRIScore(pillarScores);
//
// // Print summary
// severeData.printSummary();
//
// // Generate report
// final report = TestDataGenerator.generateTestReport(
//   assessmentData: severeData,
//   aistriScore: aistriScore,
//   pillarScores: pillarScores,
// );
//
// // Navigate to results screen
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => AssessmentResultsScreen(
//       assessmentData: severeData,
//       aistriScore: aistriScore,
//       pillarScores: pillarScores,
//     ),
//   ),
// );
// ```
