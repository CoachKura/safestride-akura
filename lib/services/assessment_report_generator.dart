// Assessment Report Generator Service
//
// Generates comprehensive post-assessment reports including:
// - Executive Summary with AISRI scores
// - Detailed ROM analysis with severity ratings
// - Gait pathology findings
// - Injury risk stratification
// - Goal-based recovery roadmap with precise timelines
// - Week-by-week protocol specifications
// - Progress tracking milestones

class AssessmentReport {
  final String athleteId;
  final DateTime assessmentDate;
  final ExecutiveSummary executiveSummary;
  final CurrentCondition currentCondition;
  final List<InjuryRisk> injuryRisks;
  final List<GaitPathology> gaitPathologies;
  final RecoveryRoadmap recoveryRoadmap;
  final List<Milestone> milestones;
  final String nextStepsRecommendation;

  AssessmentReport({
    required this.athleteId,
    required this.assessmentDate,
    required this.executiveSummary,
    required this.currentCondition,
    required this.injuryRisks,
    required this.gaitPathologies,
    required this.recoveryRoadmap,
    required this.milestones,
    required this.nextStepsRecommendation,
  });

  /// Generate formatted text report
  String generateTextReport() {
    StringBuffer report = StringBuffer();

    report.writeln('═══════════════════════════════════════════════════════');
    report.writeln('   AKURA SAFESTRIDE - COMPREHENSIVE ASSESSMENT REPORT');
    report.writeln('═══════════════════════════════════════════════════════\n');

    report.writeln('Athlete ID: $athleteId');
    report.writeln('Assessment Date: ${_formatDate(assessmentDate)}');
    report.writeln('Report Generated: ${_formatDate(DateTime.now())}\n');

    // Executive Summary
    report.writeln('─────────────────────────────────────────────────────');
    report.writeln('1. EXECUTIVE SUMMARY');
    report.writeln('─────────────────────────────────────────────────────\n');
    report.writeln(executiveSummary.generateSummary());

    // Current Condition
    report.writeln('\n─────────────────────────────────────────────────────');
    report.writeln('2. CURRENT CONDITION ANALYSIS');
    report.writeln('─────────────────────────────────────────────────────\n');
    report.writeln(currentCondition.generateConditionReport());

    // Gait Pathologies
    if (gaitPathologies.isNotEmpty) {
      report.writeln('\n─────────────────────────────────────────────────────');
      report.writeln('3. GAIT PATHOLOGY FINDINGS');
      report.writeln('─────────────────────────────────────────────────────\n');
      for (var pathology in gaitPathologies) {
        report.writeln(pathology.generatePathologyReport());
        report.writeln('');
      }
    }

    // Injury Risks
    report.writeln('\n─────────────────────────────────────────────────────');
    report.writeln('4. INJURY RISK STRATIFICATION');
    report.writeln('─────────────────────────────────────────────────────\n');
    report.writeln(_generateInjuryRiskSection());

    // Recovery Roadmap
    report.writeln('\n─────────────────────────────────────────────────────');
    report.writeln('5. GOAL-BASED RECOVERY ROADMAP');
    report.writeln('─────────────────────────────────────────────────────\n');
    report.writeln(recoveryRoadmap.generateRoadmapReport());

    // Milestones
    report.writeln('\n─────────────────────────────────────────────────────');
    report.writeln('6. PROGRESS MILESTONES & CHECKPOINTS');
    report.writeln('─────────────────────────────────────────────────────\n');
    report.writeln(_generateMilestonesSection());

    // Next Steps
    report.writeln('\n─────────────────────────────────────────────────────');
    report.writeln('7. IMMEDIATE NEXT STEPS');
    report.writeln('─────────────────────────────────────────────────────\n');
    report.writeln(nextStepsRecommendation);

    report.writeln('\n═══════════════════════════════════════════════════════');
    report.writeln('        END OF REPORT - STAY SAFE, RUN STRONG!');
    report.writeln('═══════════════════════════════════════════════════════');

    return report.toString();
  }

  String _generateInjuryRiskSection() {
    if (injuryRisks.isEmpty) {
      return '✅ No significant injury risks detected.\n';
    }

    StringBuffer section = StringBuffer();

    // Group by severity
    var critical = injuryRisks.where((r) => r.severity == 'Critical').toList();
    var high = injuryRisks.where((r) => r.severity == 'High').toList();
    var moderate = injuryRisks.where((r) => r.severity == 'Moderate').toList();
    var low = injuryRisks.where((r) => r.severity == 'Low').toList();

    if (critical.isNotEmpty) {
      section.writeln('🔴 CRITICAL RISKS (${critical.length}):');
      for (var risk in critical) {
        section.writeln('   • ${risk.area}: ${risk.injuries.join(", ")}');
      }
      section.writeln('');
    }

    if (high.isNotEmpty) {
      section.writeln('🟠 HIGH RISKS (${high.length}):');
      for (var risk in high) {
        section.writeln('   • ${risk.area}: ${risk.injuries.join(", ")}');
      }
      section.writeln('');
    }

    if (moderate.isNotEmpty) {
      section.writeln('🟡 MODERATE RISKS (${moderate.length}):');
      for (var risk in moderate) {
        section.writeln('   • ${risk.area}: ${risk.injuries.join(", ")}');
      }
      section.writeln('');
    }

    if (low.isNotEmpty) {
      section.writeln('🟢 LOW RISKS (${low.length}):');
      for (var risk in low) {
        section.writeln('   • ${risk.area}: ${risk.injuries.join(", ")}');
      }
      section.writeln('');
    }

    return section.toString();
  }

  String _generateMilestonesSection() {
    if (milestones.isEmpty) {
      return 'No specific milestones defined yet.\n';
    }

    StringBuffer section = StringBuffer();

    for (var milestone in milestones) {
      String icon = milestone.isCompleted ? '✅' : '⏳';
      section.writeln('$icon Week ${milestone.weekNumber}: ${milestone.title}');
      section.writeln('   Target Date: ${_formatDate(milestone.targetDate)}');
      section.writeln('   Expected Improvements:');
      for (var improvement in milestone.expectedImprovements) {
        section.writeln('     - $improvement');
      }
      section.writeln('   Protocol: ${milestone.protocolName}');
      section.writeln('');
    }

    return section.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class ExecutiveSummary {
  final int aistriScore;
  final String overallRiskLevel; // 'Low', 'Moderate', 'High', 'Critical'
  final Map<String, int> pillarScores;
  final List<String> criticalFindings;
  final int estimatedRecoveryWeeks;
  final String goalStatement;

  ExecutiveSummary({
    required this.aistriScore,
    required this.overallRiskLevel,
    required this.pillarScores,
    required this.criticalFindings,
    required this.estimatedRecoveryWeeks,
    required this.goalStatement,
  });

  String generateSummary() {
    StringBuffer summary = StringBuffer();

    summary.writeln('🎯 AISRI SCORE: $aistriScore/100');
    summary.writeln('📊 OVERALL RISK LEVEL: $overallRiskLevel');
    summary
        .writeln('⏱️ ESTIMATED RECOVERY TIME: $estimatedRecoveryWeeks weeks\n');

    summary.writeln('📈 PILLAR BREAKDOWN:');
    pillarScores.forEach((pillar, score) {
      String status = score >= 80
          ? '✅'
          : score >= 60
              ? '🟡'
              : '🔴';
      summary.writeln('   $status $pillar: $score/100');
    });
    summary.writeln('');

    if (criticalFindings.isNotEmpty) {
      summary.writeln('⚠️ CRITICAL FINDINGS (${criticalFindings.length}):');
      for (var finding in criticalFindings) {
        summary.writeln('   • $finding');
      }
      summary.writeln('');
    }

    summary.writeln('🎯 YOUR GOAL:');
    summary.writeln('   $goalStatement');

    return summary.toString();
  }
}

class CurrentCondition {
  final Map<String, ROMAssessment> romAssessments;
  final Map<String, int> strengthAssessments;
  final Map<String, String> qualitativeAssessments;
  final int restingHeartRate;
  final int perceivedFatigue;

  CurrentCondition({
    required this.romAssessments,
    required this.strengthAssessments,
    required this.qualitativeAssessments,
    required this.restingHeartRate,
    required this.perceivedFatigue,
  });

  String generateConditionReport() {
    StringBuffer report = StringBuffer();

    report.writeln('📋 RANGE OF MOTION ASSESSMENTS:\n');

    romAssessments.forEach((testName, assessment) {
      String icon = _getSeverityIcon(assessment.severity);
      report.writeln('$icon $testName:');
      report
          .writeln('   Your Result: ${assessment.yourValue}${assessment.unit}');
      report.writeln('   Normal Range: ${assessment.normalRange}');
      report.writeln('   Status: ${assessment.severity}');
      if (assessment.deficitPercentage != null) {
        report.writeln('   Deficit: ${assessment.deficitPercentage}%');
      }
      report.writeln('');
    });

    report.writeln('💪 STRENGTH ASSESSMENTS:\n');
    strengthAssessments.forEach((testName, reps) {
      report.writeln('   • $testName: $reps reps');
    });
    report.writeln('');

    report.writeln('📝 QUALITATIVE ASSESSMENTS:\n');
    qualitativeAssessments.forEach((testName, result) {
      report.writeln('   • $testName: $result');
    });
    report.writeln('');

    report.writeln('❤️ CARDIOVASCULAR & RECOVERY:');
    report.writeln('   • Resting Heart Rate: $restingHeartRate bpm');
    String fatigueLevel = perceivedFatigue <= 3
        ? 'Low'
        : perceivedFatigue <= 6
            ? 'Moderate'
            : 'High';
    report.writeln(
        '   • Perceived Fatigue: $perceivedFatigue/10 ($fatigueLevel)');

    return report.toString();
  }

  String _getSeverityIcon(String severity) {
    switch (severity) {
      case 'Critical':
        return '🔴';
      case 'High':
        return '🟠';
      case 'Moderate':
        return '🟡';
      case 'Normal':
        return '✅';
      default:
        return '⚪';
    }
  }
}

class ROMAssessment {
  final String testName;
  final double yourValue;
  final String unit;
  final String normalRange;
  final String severity; // 'Critical', 'High', 'Moderate', 'Normal'
  final double? deficitPercentage;

  ROMAssessment({
    required this.testName,
    required this.yourValue,
    required this.unit,
    required this.normalRange,
    required this.severity,
    this.deficitPercentage,
  });
}

class InjuryRisk {
  final String area;
  final String severity;
  final List<String> injuries;
  final String mechanismOfInjury;
  final String biomechanicalImpact;

  InjuryRisk({
    required this.area,
    required this.severity,
    required this.injuries,
    required this.mechanismOfInjury,
    required this.biomechanicalImpact,
  });
}

class GaitPathology {
  final String type;
  final String severity;
  final double confidenceLevel;
  final String description;
  final List<String> impacts;

  GaitPathology({
    required this.type,
    required this.severity,
    required this.confidenceLevel,
    required this.description,
    required this.impacts,
  });

  String generatePathologyReport() {
    StringBuffer report = StringBuffer();

    String typeName = _getPathologyTypeName(type);
    report.writeln(
        '🔍 $typeName ($severity - ${(confidenceLevel * 100).toStringAsFixed(0)}% confidence)\n');
    report.writeln(description);
    report.writeln('\n📊 BIOMECHANICAL IMPACTS:');
    for (var impact in impacts) {
      report.writeln('   • $impact');
    }

    return report.toString();
  }

  String _getPathologyTypeName(String type) {
    switch (type) {
      case 'bow_legs':
        return 'Bow Legs (Genu Varum)';
      case 'knock_knees':
        return 'Knock Knees (Genu Valgum)';
      case 'overpronation':
        return 'Overpronation';
      case 'underpronation':
        return 'Underpronation (Supination)';
      default:
        return type;
    }
  }
}

class RecoveryRoadmap {
  final String goalStatement;
  final int totalWeeks;
  final List<RoadmapPhase> phases;
  final List<String> keyPrinciples;

  RecoveryRoadmap({
    required this.goalStatement,
    required this.totalWeeks,
    required this.phases,
    required this.keyPrinciples,
  });

  String generateRoadmapReport() {
    StringBuffer report = StringBuffer();

    report.writeln('🎯 GOAL: $goalStatement');
    report.writeln('⏱️ TOTAL TIMELINE: $totalWeeks weeks\n');

    report.writeln('📅 PHASE-BY-PHASE BREAKDOWN:\n');

    for (var phase in phases) {
      report.writeln(
          '${phase.phaseNumber}. ${phase.phaseName.toUpperCase()} (Weeks ${phase.weekRange})');
      report.writeln('   🎯 Goals:');
      for (var goal in phase.goals) {
        report.writeln('      • $goal');
      }
      report.writeln('   🔧 Focus Areas:');
      for (var focus in phase.focusAreas) {
        report.writeln('      • $focus');
      }
      report.writeln('   📈 Expected Improvements:');
      for (var improvement in phase.expectedImprovements) {
        report.writeln('      • $improvement');
      }
      report.writeln('   🏃 Training Modifications:');
      for (var modification in phase.trainingModifications) {
        report.writeln('      • $modification');
      }
      report.writeln('');
    }

    report.writeln('💡 KEY PRINCIPLES FOR SUCCESS:');
    for (var principle in keyPrinciples) {
      report.writeln('   ✓ $principle');
    }

    return report.toString();
  }
}

class RoadmapPhase {
  final int phaseNumber;
  final String phaseName;
  final String weekRange;
  final List<String> goals;
  final List<String> focusAreas;
  final List<String> expectedImprovements;
  final List<String> trainingModifications;
  final String protocolName;

  RoadmapPhase({
    required this.phaseNumber,
    required this.phaseName,
    required this.weekRange,
    required this.goals,
    required this.focusAreas,
    required this.expectedImprovements,
    required this.trainingModifications,
    required this.protocolName,
  });
}

class Milestone {
  final int weekNumber;
  final String title;
  final DateTime targetDate;
  final List<String> expectedImprovements;
  final String protocolName;
  final bool isCompleted;
  final String checkpoint;

  Milestone({
    required this.weekNumber,
    required this.title,
    required this.targetDate,
    required this.expectedImprovements,
    required this.protocolName,
    this.isCompleted = false,
    required this.checkpoint,
  });
}

// Main Report Generator Class
class AssessmentReportGenerator {
  /// Generate comprehensive report from assessment data
  static AssessmentReport generateReport({
    required String athleteId,
    required Map<String, dynamic> assessmentData,
    required int aistriScore,
    required Map<String, int> pillarScores,
    required List<InjuryRisk> injuryRisks,
    required List<dynamic> gaitPathologies, // from GaitPathologyAnalyzer
    String? goalStatement,
  }) {
    // Build executive summary
    final executiveSummary = _buildExecutiveSummary(
      aistriScore: aistriScore,
      pillarScores: pillarScores,
      injuryRisks: injuryRisks,
      goalStatement: goalStatement ??
          assessmentData['goals'] ??
          'Improve running performance and reduce injury risk',
    );

    // Build current condition analysis
    final currentCondition = _buildCurrentCondition(assessmentData);

    // Convert gait pathologies
    final gaitPathologiesConverted = gaitPathologies.map((gp) {
      return GaitPathology(
        type: gp.type,
        severity: gp.severity,
        confidenceLevel: gp.confidenceLevel,
        description: gp.mechanismDescription,
        impacts: gp.biomechanicalImpacts,
      );
    }).toList();

    // Build recovery roadmap
    final recoveryRoadmap = _buildRecoveryRoadmap(
      assessmentData: assessmentData,
      injuryRisks: injuryRisks,
      gaitPathologies: gaitPathologiesConverted,
      goalStatement: goalStatement ??
          assessmentData['goals'] ??
          'Improve running performance',
    );

    // Build milestones
    final milestones = _buildMilestones(
      assessmentDate: DateTime.now(),
      totalWeeks: recoveryRoadmap.totalWeeks,
      phases: recoveryRoadmap.phases,
    );

    // Build next steps recommendation
    final nextSteps = _buildNextStepsRecommendation(
      injuryRisks: injuryRisks,
      gaitPathologies: gaitPathologiesConverted,
    );

    return AssessmentReport(
      athleteId: athleteId,
      assessmentDate: DateTime.now(),
      executiveSummary: executiveSummary,
      currentCondition: currentCondition,
      injuryRisks: injuryRisks,
      gaitPathologies: gaitPathologiesConverted,
      recoveryRoadmap: recoveryRoadmap,
      milestones: milestones,
      nextStepsRecommendation: nextSteps,
    );
  }

  static ExecutiveSummary _buildExecutiveSummary({
    required int aistriScore,
    required Map<String, int> pillarScores,
    required List<InjuryRisk> injuryRisks,
    required String goalStatement,
  }) {
    // Determine overall risk level
    String riskLevel = 'Low';
    if (aistriScore < 50) {
      riskLevel = 'Critical';
    } else if (aistriScore < 65) {
      riskLevel = 'High';
    } else if (aistriScore < 80) {
      riskLevel = 'Moderate';
    }

    // Extract critical findings
    List<String> criticalFindings = [];
    for (var risk in injuryRisks) {
      if (risk.severity == 'Critical' || risk.severity == 'High') {
        criticalFindings.add('${risk.area}: ${risk.injuries.first}');
      }
    }

    // Estimate recovery time
    int estimatedWeeks = 12; // Default
    if (riskLevel == 'Critical') {
      estimatedWeeks = 16;
    } else if (riskLevel == 'High') {
      estimatedWeeks = 12;
    } else if (riskLevel == 'Moderate') {
      estimatedWeeks = 8;
    } else {
      estimatedWeeks = 4;
    }

    return ExecutiveSummary(
      aistriScore: aistriScore,
      overallRiskLevel: riskLevel,
      pillarScores: pillarScores,
      criticalFindings: criticalFindings.take(5).toList(),
      estimatedRecoveryWeeks: estimatedWeeks,
      goalStatement: goalStatement,
    );
  }

  static CurrentCondition _buildCurrentCondition(Map<String, dynamic> a) {
    Map<String, ROMAssessment> romAssessments = {};

    // Ankle dorsiflexion
    double ankleDorsi = a['ankle_dorsiflexion_cm'] ?? 10.0;
    romAssessments['Ankle Dorsiflexion'] = ROMAssessment(
      testName: 'Ankle Dorsiflexion (Weight-Bearing Lunge)',
      yourValue: ankleDorsi,
      unit: 'cm',
      normalRange: '9-12 cm',
      severity: ankleDorsi < 7
          ? 'Critical'
          : ankleDorsi < 9
              ? 'High'
              : ankleDorsi < 12
                  ? 'Moderate'
                  : 'Normal',
      deficitPercentage: ankleDorsi < 9 ? ((9 - ankleDorsi) / 9 * 100) : null,
    );

    // Hip flexion
    int hipFlexion = a['hip_flexion_angle'] ?? 120;
    romAssessments['Hip Flexion'] = ROMAssessment(
      testName: 'Hip Flexion (Knee-to-Chest)',
      yourValue: hipFlexion.toDouble(),
      unit: '°',
      normalRange: '110-130°',
      severity: hipFlexion < 100
          ? 'Critical'
          : hipFlexion < 110
              ? 'High'
              : hipFlexion < 120
                  ? 'Moderate'
                  : 'Normal',
      deficitPercentage:
          hipFlexion < 110 ? ((110 - hipFlexion) / 110 * 100) : null,
    );

    // Add more ROM assessments as needed...

    Map<String, int> strengthAssessments = {
      'Hip Abduction': a['hip_abduction_reps'] ?? 20,
      'Plank Hold': a['plank_hold_seconds'] ?? 45,
      'Single-Leg Balance': a['balance_test_seconds'] ?? 15,
    };

    Map<String, String> qualitativeAssessments = {
      'Knee Extension Strength':
          a['knee_extension_strength'] ?? 'Moderate (45-90°)',
      'Shoulder Internal Rotation':
          a['shoulder_internal_rotation'] ?? 'Mid-back',
      'Neck Flexion': a['neck_flexion_status'] ?? 'Within 2cm',
    };

    return CurrentCondition(
      romAssessments: romAssessments,
      strengthAssessments: strengthAssessments,
      qualitativeAssessments: qualitativeAssessments,
      restingHeartRate: a['resting_heart_rate'] ?? 70,
      perceivedFatigue: a['perceived_fatigue'] ?? 5,
    );
  }

  static RecoveryRoadmap _buildRecoveryRoadmap({
    required Map<String, dynamic> assessmentData,
    required List<InjuryRisk> injuryRisks,
    required List<GaitPathology> gaitPathologies,
    required String goalStatement,
  }) {
    int totalWeeks = 12; // Default

    // Determine timeline based on severity
    int criticalCount =
        injuryRisks.where((r) => r.severity == 'Critical').length;
    int highCount = injuryRisks.where((r) => r.severity == 'High').length;

    if (criticalCount >= 3 ||
        gaitPathologies.where((gp) => gp.severity == 'Severe').length >= 2) {
      totalWeeks = 16;
    } else if (criticalCount >= 1 || highCount >= 3) {
      totalWeeks = 12;
    } else if (highCount >= 1) {
      totalWeeks = 8;
    } else {
      totalWeeks = 6;
    }

    List<RoadmapPhase> phases = [];

    // Phase 1: Foundation & Acute Correction
    phases.add(RoadmapPhase(
      phaseNumber: 1,
      phaseName: 'Foundation & Acute Correction',
      weekRange: '1-${(totalWeeks / 4).ceil()}',
      goals: [
        'Establish baseline mobility and strength',
        'Reduce acute injury risk factors',
        'Begin neuromuscular re-education',
      ],
      focusAreas: [
        'Daily mobility work (ankles, hips, shoulders)',
        'Corrective exercise introduction',
        'Training load reduction (40-50%)',
      ],
      expectedImprovements: [
        'Pain/discomfort reduction: 30-40%',
        'ROM improvements: +5-10% in deficient areas',
        'Movement quality awareness increases',
      ],
      trainingModifications: [
        'Reduce weekly mileage by 40-50%',
        'Easy pace only (no speed work)',
        'Flat, even surfaces only',
      ],
      protocolName: 'Foundation Protocol',
    ));

    // Phase 2: Functional Strengthening
    phases.add(RoadmapPhase(
      phaseNumber: 2,
      phaseName: 'Functional Strengthening',
      weekRange: '${(totalWeeks / 4).ceil() + 1}-${(totalWeeks / 2).ceil()}',
      goals: [
        'Build functional strength patterns',
        'Integrate corrective exercises into running',
        'Progress training volume gradually',
      ],
      focusAreas: [
        'Resistance training progression',
        'Single-leg stability work',
        'Gait pattern drills',
      ],
      expectedImprovements: [
        'ROM improvements: +15-25% total',
        'Strength gains: 20-30% in weak areas',
        'Running economy improves 10-15%',
      ],
      trainingModifications: [
        'Increase mileage to 70-75% of baseline',
        'Introduce tempo runs (if pain-free)',
        'Begin gentle hill work (uphills only)',
      ],
      protocolName: 'Functional Strength Protocol',
    ));

    // Phase 3: Integration & Performance
    phases.add(RoadmapPhase(
      phaseNumber: 3,
      phaseName: 'Integration & Performance',
      weekRange:
          '${(totalWeeks / 2).ceil() + 1}-${(totalWeeks * 3 / 4).ceil()}',
      goals: [
        'Integrate strength into performance',
        'Restore full training capacity',
        'Build resilience for high-intensity work',
      ],
      focusAreas: [
        'Sport-specific strength work',
        'Plyometric progression',
        'Speed work reintroduction',
      ],
      expectedImprovements: [
        'ROM near-normal ranges (90%+ of optimal)',
        'Strength plateaus (maintain gains)',
        'Running economy restored (95%+ of potential)',
      ],
      trainingModifications: [
        'Increase to 90-95% baseline mileage',
        'Full speed/interval work',
        'Varied terrain (including trails)',
      ],
      protocolName: 'Performance Integration Protocol',
    ));

    // Phase 4: Maintenance & Optimization
    phases.add(RoadmapPhase(
      phaseNumber: 4,
      phaseName: 'Maintenance & Optimization',
      weekRange: '${(totalWeeks * 3 / 4).ceil() + 1}-$totalWeeks',
      goals: [
        'Maintain all gains',
        'Establish long-term habits',
        'Optimize peak performance',
      ],
      focusAreas: [
        'Maintenance strength routine (2-3x/week)',
        'Preventive mobility work',
        'Performance testing',
      ],
      expectedImprovements: [
        'Full ROM restoration (100%)',
        'Peak performance capacity',
        'Injury risk minimized',
      ],
      trainingModifications: [
        '100% training volume',
        'Full intensity range',
        'Racing if desired',
      ],
      protocolName: 'Maintenance Protocol',
    ));

    List<String> keyPrinciples = [
      'NEVER skip mobility work - it\'s the foundation',
      'Progress gradually - don\'t rush the phases',
      'Listen to your body - pain is a signal, not weakness',
      'Consistency beats intensity - daily small efforts compound',
      'Maintenance is lifelong - keep these habits forever',
    ];

    return RecoveryRoadmap(
      goalStatement: goalStatement,
      totalWeeks: totalWeeks,
      phases: phases,
      keyPrinciples: keyPrinciples,
    );
  }

  static List<Milestone> _buildMilestones({
    required DateTime assessmentDate,
    required int totalWeeks,
    required List<RoadmapPhase> phases,
  }) {
    List<Milestone> milestones = [];

    // Week 2: Early Adaptation
    milestones.add(Milestone(
      weekNumber: 2,
      title: 'Early Adaptation Checkpoint',
      targetDate: assessmentDate.add(Duration(days: 14)),
      expectedImprovements: [
        'Noticeable reduction in pain/discomfort',
        'Improved awareness of movement patterns',
        'Corrective exercises feel more natural',
      ],
      protocolName: 'Foundation Protocol',
      checkpoint: 'Re-test ankle dorsiflexion, balance test',
    ));

    // Week 4: Quarter-Point
    milestones.add(Milestone(
      weekNumber: 4,
      title: 'Quarter-Point Progress Check',
      targetDate: assessmentDate.add(Duration(days: 28)),
      expectedImprovements: [
        '+1-2cm ankle dorsiflexion',
        '+5-10 reps hip abduction strength',
        '10-15% running economy improvement',
      ],
      protocolName:
          phases.length > 1 ? phases[1].protocolName : 'Foundation Protocol',
      checkpoint: 'Full ROM re-assessment, compare to baseline',
    ));

    // Mid-point
    int midWeek = (totalWeeks / 2).ceil();
    milestones.add(Milestone(
      weekNumber: midWeek,
      title: 'Mid-Program Assessment',
      targetDate: assessmentDate.add(Duration(days: midWeek * 7)),
      expectedImprovements: [
        'ROM improvements: 50-60% of target',
        'Strength gains: 30-40% increase',
        'Pain/discomfort minimal or absent',
      ],
      protocolName: phases.length > 2
          ? phases[2].protocolName
          : 'Functional Strength Protocol',
      checkpoint: 'Full AISRI re-assessment, adjust program if needed',
    ));

    // Three-quarter point
    int threeQuarterWeek = (totalWeeks * 3 / 4).ceil();
    milestones.add(Milestone(
      weekNumber: threeQuarterWeek,
      title: 'Performance Restoration Check',
      targetDate: assessmentDate.add(Duration(days: threeQuarterWeek * 7)),
      expectedImprovements: [
        'ROM near-optimal (90%+)',
        'Full training volume resumed',
        'Injury risk significantly reduced',
      ],
      protocolName: phases.length > 3
          ? phases[3].protocolName
          : 'Performance Integration Protocol',
      checkpoint: 'Performance testing, time trial or race pace workout',
    ));

    // Final milestone
    milestones.add(Milestone(
      weekNumber: totalWeeks,
      title: 'Program Completion & Optimization',
      targetDate: assessmentDate.add(Duration(days: totalWeeks * 7)),
      expectedImprovements: [
        'All ROM targets achieved',
        'Peak performance capacity',
        'Maintenance routine established',
      ],
      protocolName: 'Maintenance Protocol',
      checkpoint: 'Final AISRI assessment, celebrate success!',
    ));

    return milestones;
  }

  static String _buildNextStepsRecommendation({
    required List<InjuryRisk> injuryRisks,
    required List<GaitPathology> gaitPathologies,
  }) {
    StringBuffer steps = StringBuffer();

    steps.writeln('📋 IMMEDIATE ACTION ITEMS:\n');

    steps.writeln('1. START YOUR CORRECTIVE PROGRAM TODAY');
    steps.writeln('   • Review Phase 1 exercises in the Rehab Program screen');
    steps.writeln('   • Set daily reminders for mobility work');
    steps.writeln('   • Download exercise videos for reference\n');

    steps.writeln('2. MODIFY YOUR TRAINING IMMEDIATELY');
    steps.writeln('   • Reduce weekly mileage as specified in Phase 1');
    steps.writeln('   • Cancel any scheduled races in next 4-6 weeks');
    steps.writeln('   • Focus on easy-pace runs only\n');

    if (gaitPathologies.isNotEmpty) {
      steps.writeln('3. ADDRESS GAIT ISSUES');
      steps.writeln(
          '   • Review footwear recommendations in Gait Analysis section');
      steps.writeln('   • Consider professional gait analysis video');
      steps.writeln('   • Implement terrain modifications\n');
    }

    if (injuryRisks.where((r) => r.severity == 'Critical').isNotEmpty) {
      steps.writeln(
          '⚠️ CRITICAL: Consider consulting a sports medicine professional');
      steps.writeln(
          '   Your assessment indicates high injury risk in critical areas.');
      steps.writeln(
          '   A physical therapist can provide hands-on assessment and treatment.\n');
    }

    steps.writeln('4. TRACK YOUR PROGRESS');
    steps.writeln('   • Schedule milestone re-assessments in your calendar');
    steps.writeln('   • Log daily exercise completion');
    steps.writeln('   • Monitor pain levels and running metrics\n');

    steps.writeln('5. STAY COMMITTED');
    steps.writeln('   • This is a marathon, not a sprint');
    steps.writeln('   • Small daily efforts compound into major results');
    steps.writeln('   • Your future running self will thank you!');

    return steps.toString();
  }
}
