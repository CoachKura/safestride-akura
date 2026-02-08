// Biomechanics Reference Data
//
// Evidence-based thresholds, force vectors, and muscle activation patterns
// for running gait analysis. All values based on peer-reviewed research.

// ROM Standards and Thresholds

class ROMStandards {
  // Ankle Dorsiflexion (Weight-Bearing Lunge Test)
  // Research: Howe et al. (2011)
  static const double ankleDorsiflexionCritical = 7.0; // cm
  static const double ankleDorsiflexionHigh = 9.0;
  static const double ankleDorsiflexionNormal = 12.0;
  static const double ankleDorsiflexionExcellent = 12.0;

  // Injury risk multipliers
  static const double ankleLessThan7cmRisk = 2.5; // 2.5x Achilles risk
  static const double ankleLessThan9cmRisk = 1.25; // 1.25x shin splint risk

  // Injury risk percentages
  static const int ankleLessThan7cmRiskPercent = 40; // +40% Achilles risk
  static const int ankleLessThan9cmRiskPercent = 25; // +25% shin splint risk
  static const int ankleGreaterThan12cmReduction =
      -20; // -20% lower leg injuries
  static const int anklePerCmPowerLoss =
      10; // Each 1cm deficit = ~10% power loss
  static const int anklePerCmStrideLengthGain =
      5; // Each 1cm = ~5% stride length

  // Hip Flexion (Knee-to-Chest)
  static const int hipFlexionCritical = 100; // degrees
  static const int hipFlexionHigh = 110;
  static const int hipFlexionNormal = 130;
  static const int hipFlexionHypermobile = 130;

  // Hip Abduction Strength (Single-Leg Raises)
  // Research: Fredericson et al. (2000)
  static const int hipAbductionCritical = 15; // reps
  static const int hipAbductionHigh = 20;
  static const int hipAbductionNormal = 30;
  static const int hipAbductionStrong = 30;

  // Balance Test (Single-Leg Stance)
  static const int balanceCritical = 8; // seconds
  static const int balanceHigh = 15;
  static const int balanceNormal = 30;

  // Core Strength (Plank Hold)
  static const int plankCritical = 30; // seconds
  static const int plankHigh = 60;
  static const int plankNormal = 90;

  /// Get severity classification for ankle dorsiflexion
  static String classifyAnkleDorsiflexion(double cm) {
    if (cm < ankleDorsiflexionCritical) return 'Critical';
    if (cm < ankleDorsiflexionHigh) return 'High';
    if (cm < ankleDorsiflexionNormal) return 'Normal';
    return 'Excellent';
  }

  /// Get severity classification for hip abduction
  static String classifyHipAbduction(int reps) {
    if (reps < hipAbductionCritical) return 'Critical';
    if (reps < hipAbductionHigh) return 'High';
    if (reps < hipAbductionNormal) return 'Normal';
    return 'Strong';
  }

  /// Calculate injury risk multiplier based on ankle dorsiflexion
  static double getAnkleInjuryRiskMultiplier(double cm) {
    if (cm < 7.0) return ankleLessThan7cmRisk;
    if (cm < 9.0) return ankleLessThan9cmRisk;
    return 1.0;
  }
}

// Gait Cycle Phases and Timing
class GaitCyclePhases {
  // Phase 1: Heel Strike (0-20ms)
  static const int heelStrikeStart = 0;
  static const int heelStrikeEnd = 20;
  static const double heelStrikeForce = 2.0; // x body weight

  // Phase 2: Early Midstance (20-100ms)
  static const int earlyMidstanceStart = 20;
  static const int earlyMidstanceEnd = 100;
  static const double earlyMidstanceForce = 3.0; // peak GRF

  // Phase 3: Late Midstance (100-150ms)
  static const int lateMidstanceStart = 100;
  static const int lateMidstanceEnd = 150;
  static const double lateMidstanceForce = 2.5;

  // Phase 4: Push-Off (150-250ms)
  static const int pushOffStart = 150;
  static const int pushOffEnd = 250;
  static const double pushOffForce = 3.0;

  // Total ground contact time at moderate pace
  static const int totalContactTime = 225; // ms (average 200-250)

  // Normal pronation parameters
  static const double normalPronationDegrees = 6.0; // 4-8° range
  static const int normalPronationTime = 100; // ms

  // Horizontal force components (braking/propulsive)
  static const double brakingForceMin = -0.2; // x body weight
  static const double brakingForceMax = -0.5; // x body weight
  static const double propulsiveForceMin = 0.2; // x body weight
  static const double propulsiveForceMax = 0.5; // x body weight

  // Achilles tendon energy storage
  static const int achillesTendonEnergyStorage =
      35; // Joules during late midstance
}

// Force Vector Data for Different Pathologies
class ForceVectorData {
  final double verticalForce; // x body weight
  final double lateralForce; // x body weight
  final String lateralDirection; // "medial", "lateral", or "neutral"
  final int contactDuration; // milliseconds

  const ForceVectorData({
    required this.verticalForce,
    required this.lateralForce,
    required this.lateralDirection,
    required this.contactDuration,
  });

  // Normal gait forces
  static const normal = ForceVectorData(
    verticalForce: 2.75,
    lateralForce: 0.075,
    lateralDirection: 'neutral',
    contactDuration: 225,
  );

  // Bow legs (Genu Varum)
  static const bowLegs = ForceVectorData(
    verticalForce: 3.0,
    lateralForce: 0.175,
    lateralDirection: 'lateral',
    contactDuration: 200,
  );

  // Knock knees (Genu Valgum)
  static const knockKnees = ForceVectorData(
    verticalForce: 2.85,
    lateralForce: 0.175,
    lateralDirection: 'medial',
    contactDuration: 245,
  );

  // Overpronation
  static const overpronation = ForceVectorData(
    verticalForce: 2.75,
    lateralForce: 0.125,
    lateralDirection: 'medial',
    contactDuration: 265,
  );

  // Underpronation (Supination)
  static const underpronation = ForceVectorData(
    verticalForce: 3.25,
    lateralForce: 0.175,
    lateralDirection: 'lateral',
    contactDuration: 190,
  );

  /// Get force description for reports
  String getForceDescription() {
    return 'Vertical: ${verticalForce.toStringAsFixed(1)}x BW, '
        'Lateral: ${lateralForce.toStringAsFixed(2)}x BW ($lateralDirection), '
        'Contact: ${contactDuration}ms';
  }
}

// Running Economy Impact Data
class RunningEconomyImpact {
  final double economyLossPercent;
  final double vo2IncreasePercent;
  final double energyCostKcalPerKgKm;
  final int marathonTimeIncreaseMins;

  const RunningEconomyImpact({
    required this.economyLossPercent,
    required this.vo2IncreasePercent,
    required this.energyCostKcalPerKgKm,
    required this.marathonTimeIncreaseMins,
  });

  static const normal = RunningEconomyImpact(
    economyLossPercent: 0.0,
    vo2IncreasePercent: 0.0,
    energyCostKcalPerKgKm: 1.0,
    marathonTimeIncreaseMins: 0,
  );

  static const bowLegs = RunningEconomyImpact(
    economyLossPercent: 10.0,
    vo2IncreasePercent: 12.5,
    energyCostKcalPerKgKm: 1.10,
    marathonTimeIncreaseMins: 10,
  );

  static const knockKnees = RunningEconomyImpact(
    economyLossPercent: 12.5,
    vo2IncreasePercent: 15.0,
    energyCostKcalPerKgKm: 1.15,
    marathonTimeIncreaseMins: 13,
  );

  static const overpronation = RunningEconomyImpact(
    economyLossPercent: 9.0,
    vo2IncreasePercent: 11.0,
    energyCostKcalPerKgKm: 1.10,
    marathonTimeIncreaseMins: 9,
  );

  static const underpronation = RunningEconomyImpact(
    economyLossPercent: 11.0,
    vo2IncreasePercent: 13.5,
    energyCostKcalPerKgKm: 1.12,
    marathonTimeIncreaseMins: 11,
  );

  String getSummary() {
    return 'Running economy: -${economyLossPercent.toStringAsFixed(1)}% | '
        'Energy cost: +${((energyCostKcalPerKgKm - 1.0) * 100).toStringAsFixed(0)}% | '
        'Marathon impact: ~+$marathonTimeIncreaseMins minutes';
  }
}

// Normal Running Muscle Activation Timing
class MuscleActivationTiming {
  // Pre-activation phase (100ms before heel contact)
  static const int preActivationStart = -100; // ms
  static const Map<String, double> preActivation = {
    'tibialisAnterior': 70.0, // % max (60-80% range)
    'gluteMedius': 50.0, // % max (40-60% range)
    'hamstrings': 40.0, // % max (30-50% range)
    'quadriceps': 50.0, // % max (40-60% range)
  };

  // Contact phase (0-150ms)
  static const Map<String, double> contactPhase = {
    'quadriceps': 90.0, // % max (80-100% - eccentric)
    'gluteMaximus': 70.0, // % max (60-80%)
    'gastrocnemius': 50.0, // % max (40-60%)
    'soleus': 50.0, // % max (40-60%)
    'gluteMedius': 80.0, // % max (70-90% - frontal control)
  };

  // Push-off phase (150-250ms)
  static const Map<String, double> pushOffPhase = {
    'plantarflexors': 105.0, // % max (90-120% - explosive)
    'hipExtensors': 80.0, // % max (70-90%)
    'toeFlexors': 70.0, // % max (60-80%)
  };

  // Timing delays in pathological patterns
  static const int gluteMediusDelayKnockKnees = 75; // ms (50-100ms range)
  static const int archCollapseDelayOverpronation = 65; // ms (50-80ms range)
}

// Muscle Activation Patterns
class MuscleActivationPattern {
  final String muscleName;
  final double normalActivation; // % of max
  final double pathologicalActivation; // % of max
  final String status; // "overactive", "underactive", "delayed", "normal"
  final int? delayMs; // if delayed activation

  const MuscleActivationPattern({
    required this.muscleName,
    required this.normalActivation,
    required this.pathologicalActivation,
    required this.status,
    this.delayMs,
  });

  String getDescription() {
    String desc = '$muscleName: ${pathologicalActivation.toStringAsFixed(0)}% ';
    if (status == 'overactive') {
      desc += '(overactive, normal: ${normalActivation.toStringAsFixed(0)}%)';
    } else if (status == 'underactive') {
      desc += '(underactive, normal: ${normalActivation.toStringAsFixed(0)}%)';
    } else if (status == 'delayed') {
      desc += '(delayed ${delayMs}ms)';
    }
    return desc;
  }
}

// Injury Risk Data for Each Pathology
class InjuryRiskData {
  // Bow Legs (Genu Varum) injury risks
  static const int bowLegsLateralKneeOA = 65; // +65% risk
  static const int bowLegsITBandSyndrome = 55; // +55% risk
  static const int bowLegsStressFractures = 45; // +45% risk (fibula, 5th MT)
  static const int bowLegsLateralAnkleInstability = 40; // +40% risk

  // Knock Knees (Genu Valgum) injury risks
  static const int knockKneesPatellofemoralPain = 70; // +70% risk
  static const int knockKneesMedialKneeOA = 55; // +55% risk
  static const int knockKneesITBandSyndrome = 50; // +50% risk
  static const int knockKneesShinSplints = 50; // +50% risk
  static const int knockKneesACLInjury =
      300; // +300% risk (Hewett et al., 2005)

  // Overpronation injury risks
  static const int overpronationPlantarFasciitis = 60; // +60% risk
  static const int overpronationPTT =
      55; // +55% risk (posterior tibial tendinopathy)
  static const int overpronationShinSplints = 55; // +55% risk
  static const int overpronationAchillesTendinopathy = 50; // +50% risk

  // Underpronation injury risks
  static const int underpronationLateralAnkleSprains = 70; // +70% risk
  static const int underpronationStressFractures =
      60; // +60% risk (MT 4-5, fibula)
  static const int underpronationPeronealTendinopathy = 50; // +50% risk
  static const int underpronationITBandSyndrome = 45; // +45% risk
}

// Gait Pathology Detection Thresholds
class GaitDetectionThresholds {
  // Bow Legs (Genu Varum)
  static const Map<String, double> bowLegs = {
    'hipAbductionHigh': 0.30, // >35 reps (adductor weakness)
    'ankleDorsiflexionLow': 0.25, // <9cm (tight calves)
    'balanceLow': 0.20, // <15 sec (lateral instability)
    'injuryHistory': 0.25, // IT band/lateral knee
    'threshold': 0.50, // minimum confidence to detect
  };

  // Knock Knees (Genu Valgum)
  static const Map<String, double> knockKnees = {
    'hipAbductionLow': 0.35, // <20 reps (weak glute medius)
    'balanceLow': 0.30, // <15 sec (poor stability)
    'kneeFlexionGap': 0.15, // >8cm gap (tracking issue)
    'injuryHistory': 0.20, // patellofemoral pain
    'threshold': 0.50,
  };

  // Overpronation
  static const Map<String, double> overpronation = {
    'ankleDorsiflexionLow': 0.25, // <9cm (tight calves)
    'hipAbductionLow': 0.30, // <20 reps (weak hips)
    'coreStrength': 0.20, // <40 sec plank (proximal instability)
    'injuryHistory': 0.25, // plantar fasciitis/PTT/Achilles
    'threshold': 0.50,
  };

  // Underpronation (Supination)
  static const Map<String, double> underpronation = {
    'ankleDorsiflexionVeryLow': 0.35, // <8cm (rigid ankle)
    'balanceVeryLow': 0.25, // <12 sec (high arch instability)
    'hamstringFlexibility': 0.15, // <-5cm (overall stiffness)
    'injuryHistory': 0.25, // stress fracture/ankle sprain
    'threshold': 0.50,
  };
}

// Clinical Decision Rules
class ClinicalDecisionRules {
  /// Determine if immediate professional referral is needed
  static bool requiresImmediateReferral(Map<String, dynamic> assessment) {
    final ankleDorsi = assessment['ankle_dorsiflexion_cm'] as double? ?? 10.0;
    final balance = assessment['balance_test_seconds'] as int? ?? 15;
    final currentPain = assessment['current_pain'] as String? ?? '';

    // Critical thresholds
    if (ankleDorsi < 6.0 && currentPain.toLowerCase().contains('pain'))
      return true;
    if (balance < 8) return true; // Severe instability

    return false;
  }

  /// Determine if high priority referral (2-4 weeks) is needed
  static bool requiresHighPriorityReferral(Map<String, dynamic> assessment) {
    final ankleDorsi = assessment['ankle_dorsiflexion_cm'] as double? ?? 10.0;
    final hipAbduction = assessment['hip_abduction_reps'] as int? ?? 20;
    final previousInjuries = assessment['previous_injuries'] as String? ?? '';

    if (ankleDorsi < 7.0) return true;
    if (hipAbduction < 15) return true;

    // Count recurrent injuries
    final injuryCount = previousInjuries.toLowerCase().split(',').length;
    if (injuryCount >= 3) return true;

    return false;
  }

  /// Get referral recommendation string
  static String getReferralRecommendation(Map<String, dynamic> assessment) {
    if (requiresImmediateReferral(assessment)) {
      return '🚨 IMMEDIATE REFERRAL RECOMMENDED: Severe deficits detected. '
          'Consult a physical therapist or sports medicine physician within 1 week.';
    }
    if (requiresHighPriorityReferral(assessment)) {
      return '⚠️ HIGH PRIORITY REFERRAL: Significant issues detected. '
          'Schedule evaluation with a physical therapist within 2-4 weeks.';
    }
    return '✅ MODERATE RISK: Continue with corrective exercises. '
        'Reassess in 4-6 weeks. If no improvement, seek professional evaluation.';
  }
}

// Corrective Exercise Timelines
class CorrectiveTimeline {
  static const phase1Duration = 2; // weeks
  static const phase2Duration = 4; // weeks
  static const phase3Duration = 4; // weeks
  static const phase4Duration = 4; // weeks (minimum)

  /// Phase 1: Neural Adaptation (Weeks 1-2)
  static const phase1 = {
    'name': 'Neural Adaptation',
    'mechanism': 'Improved motor unit recruitment',
    'strengthGain': '10-20%',
    'romChange': '1-2cm',
    'injuryRiskReduction': '10-15%',
  };

  /// Phase 2: Structural Adaptation (Weeks 3-6)
  static const phase2 = {
    'name': 'Structural Adaptation',
    'mechanism': 'Muscle hypertrophy, tendon stiffness',
    'strengthGain': '20-35%',
    'romChange': '2-4cm',
    'injuryRiskReduction': '30-40%',
  };

  /// Phase 3: Functional Integration (Weeks 7-10)
  static const phase3 = {
    'name': 'Functional Integration',
    'mechanism': 'Movement pattern retraining',
    'strengthGain': '30-50%',
    'romChange': '90%+ of target',
    'runningEconomyRestored': '85-95%',
  };

  /// Phase 4: Maintenance (Weeks 11+)
  static const phase4 = {
    'name': 'Maintenance',
    'mechanism': 'Habit formation, resilience building',
    'strengthGain': 'Maintain all improvements',
    'romChange': 'Full restoration',
    'injuryRisk': 'Minimized (low risk)',
  };
}

// Research Citations
class ResearchCitations {
  static const ankleDorsiflexion =
      'Howe et al. (2011) - Weight-bearing lunge test validity';
  static const hipAbduction =
      'Fredericson et al. (2000) - Hip abductor mechanics in IT band syndrome';
  static const kneeValgus =
      'Hewett et al. (2005) - Dynamic knee valgus and ACL injury mechanisms';
  static const pronationVelocity =
      'Hamill et al. (1992) - Foot kinematics during running';
  static const overpronationMechanics =
      'Cornwall & McPoil (1999) - Foot mechanics and pronation';
  static const gluteStrengthening =
      'Selkowitz et al. (2013) - Glute medius activation exercises';
  static const ankleMobility =
      'Hoch & McKeon (2011) - Dorsiflexion improvements post-intervention';
  static const copenhagenPlank =
      'Thorborg et al. (2016) - Hip adduction strength protocols';
}
