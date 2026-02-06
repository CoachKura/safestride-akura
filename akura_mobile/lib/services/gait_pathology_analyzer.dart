/// Gait Pathology Analyzer Service
/// 
/// Detects and analyzes specific gait abnormalities:
/// - Bow Legs (Genu Varum)
/// - Knock Knees (Genu Valgum)  
/// - Overpronation (Excessive Pronation)
/// - Underpronation (Supination)
/// - Neutral but inefficient patterns
///
/// Uses physical assessment data to infer gait patterns and predict injury risks

import 'package:flutter/foundation.dart';
import 'biomechanics_reference.dart';

class GaitPathology {
  final String type; // 'bow_legs', 'knock_knees', 'overpronation', 'underpronation', 'neutral'
  final String severity; // 'Mild', 'Moderate', 'Severe'
  final double confidenceLevel; // 0.0 to 1.0
  final String mechanismDescription;
  final List<String> associatedInjuries;
  final List<String> biomechanicalImpacts;
  final String correctiveStrategy;
  final List<Exercise> specificExercises;
  final String footwearRecommendation;
  final String terrainModifications;
  final ForceVectorData forceVectors;
  final RunningEconomyImpact economyImpact;
  final List<MuscleActivationPattern> musclePatterns;

  GaitPathology({
    required this.type,
    required this.severity,
    required this.confidenceLevel,
    required this.mechanismDescription,
    required this.associatedInjuries,
    required this.biomechanicalImpacts,
    required this.correctiveStrategy,
    required this.specificExercises,
    required this.footwearRecommendation,
    required this.terrainModifications,
    required this.forceVectors,
    required this.economyImpact,
    required this.musclePatterns,
  });
  
  // Convenience getters
  String get pathologyName => type.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  double get confidence => confidenceLevel;
}

class Exercise {
  final String name;
  final String description;
  final int sets;
  final int reps;
  final String frequency;
  final String progressionTimeline;

  Exercise({
    required this.name,
    required this.description,
    required this.sets,
    required this.reps,
    required this.frequency,
    required this.progressionTimeline,
  });
}

class GaitPathologyAnalyzer {
  
  /// Analyze all gait patterns from assessment data
  static List<GaitPathology> analyzeGaitPatterns(Map<String, dynamic> assessment) {
    List<GaitPathology> pathologies = [];
    
    // Check for bow legs (genu varum)
    final bowLegs = _analyzeBowLegs(assessment);
    if (bowLegs != null) pathologies.add(bowLegs);
    
    // Check for knock knees (genu valgum)
    final knockKnees = _analyzeKnockKnees(assessment);
    if (knockKnees != null) pathologies.add(knockKnees);
    
    // Check for overpronation
    final overpronation = _analyzeOverpronation(assessment);
    if (overpronation != null) pathologies.add(overpronation);
    
    // Check for underpronation (supination)
    final underpronation = _analyzeUnderpronation(assessment);
    if (underpronation != null) pathologies.add(underpronation);
    
    return pathologies;
  }
  
  /// Detect BOW LEGS (Genu Varum) - Knees bow outward
  /// 
  /// Research-Based Detection Criteria (GaitDetectionThresholds.bowLegs):
  /// - Hip abduction >35 reps: +0.30 (adductor weakness)
  /// - Ankle dorsiflexion <9cm: +0.25 (tight calves)
  /// - Balance <15 sec: +0.20 (lateral instability)
  /// - IT band/lateral knee history: +0.25
  /// - Threshold: 0.50 confidence to detect
  static GaitPathology? _analyzeBowLegs(Map<String, dynamic> a) {
    double confidence = 0.0;
    String severity = 'Mild';
    
    // Use research-based thresholds
    final thresholds = GaitDetectionThresholds.bowLegs;
    
    // Check hip abduction strength (proxy for adductor weakness)
    int hipAbduction = a['hip_abduction_reps'] ?? 20;
    if (hipAbduction > 35) {
      confidence += thresholds['hipAbductionHigh']!;
    }
    
    // Check ankle dorsiflexion (bow legs often have tight calves)
    double ankleDorsi = a['ankle_dorsiflexion_cm'] ?? 10.0;
    if (ankleDorsi < ROMStandards.ankleDorsiflexionHigh) {
      confidence += thresholds['ankleDorsiflexionLow']!;
    }
    
    // Check balance (bow legs have lateral instability)
    int balance = a['balance_test_seconds'] ?? 15;
    if (balance < ROMStandards.balanceHigh) {
      confidence += thresholds['balanceLow']!;
    }
    
    // Check injury history for lateral knee pain or IT band syndrome
    String injuryHistory = (a['previous_injuries'] ?? '').toLowerCase();
    if (injuryHistory.contains('it band') || 
        injuryHistory.contains('lateral knee') ||
        injuryHistory.contains('peroneal')) {
      confidence += thresholds['injuryHistory']!;
    }
    
    // If confidence < threshold, not detected
    if (confidence < thresholds['threshold']!) return null;
    
    // Determine severity based on confidence
    if (confidence >= 0.8) {
      severity = 'Severe';
    } else if (confidence >= 0.65) {
      severity = 'Moderate';
    }
    
    return GaitPathology(
      type: 'bow_legs',
      severity: severity,
      confidenceLevel: confidence,
      mechanismDescription: '''
🦵 BOW LEGS (Genu Varum) BIOMECHANICS:

📐 STRUCTURAL ALIGNMENT:
• Knees bow outward when standing
• Increased lateral knee joint space
• Tibiofemoral angle: >5-10° varus deviation
• Weight-bearing line passes lateral to knee center

🏃 RUNNING GAIT IMPACT:

1. HEEL STRIKE PHASE:
   • Lateral heel strike (supinated foot position)
   • Increased ground reaction force on lateral foot
   • Reduced shock absorption (rigid foot)
   • Forces transmitted up lateral leg

2. MIDSTANCE PHASE:
   • Poor foot pronation (stays supinated)
   • Lateral knee compartment compression
   • Increased tibiofibular stress
   • IT band tension increases

3. PUSH-OFF PHASE:
   • Power generation from lateral foot
   • Inefficient energy transfer
   • Increased peroneal muscle demand
   • Lateral ankle instability

⚡ FORCE VECTOR ANALYSIS:
• Ground reaction force: 2.5-3.0x body weight
• 60-70% concentrated on lateral knee compartment (normal: 50%)
• Increased varus moment at knee: +35% stress
• Lateral tibial plateau pressure: +40-50%

💪 MUSCLE ACTIVATION PATTERNS:
• Overactive: Tensor Fasciae Latae (TFL), IT band, Peroneals
• Underactive: Hip adductors, Vastus Medialis Oblique (VMO)
• Compensation: Lateral trunk lean during stance phase
• Energy cost: +8-12% compared to neutral alignment
      ''',
      associatedInjuries: [
        'Lateral Knee Osteoarthritis (+65% risk)',
        'IT Band Syndrome (+55% risk)',
        'Stress Fractures (Fibula, 5th Metatarsal) (+45% risk)',
        'Peroneal Tendinopathy (+40% risk)',
        'Lateral Ankle Sprains (+50% risk)',
        'Lateral Meniscus Damage (+35% risk)',
      ],
      biomechanicalImpacts: [
        '🔴 Running Economy: -8 to -12% efficiency loss',
        '🔴 Stride Length: Reduced by 5-8% (protective mechanism)',
        '🔴 Ground Contact Time: +12-15ms (lateral instability)',
        '🔴 Cadence: Increases +5-8 steps/min (shorter stride compensation)',
        '🔴 Vertical Oscillation: +2-3cm (poor shock absorption)',
        '🔴 Ankle Power: -15% push-off power',
        '🟡 Knee Flexion: Reduced by 3-5° (lateral compartment protection)',
        '🟡 Hip Adduction: Limited (-10° less than neutral)',
      ],
      correctiveStrategy: '''
🎯 3-PHASE CORRECTION STRATEGY:

PHASE 1: STRUCTURAL BALANCE (Weeks 1-4)
Goal: Reduce lateral bias, strengthen medial structures

PHASE 2: FUNCTIONAL INTEGRATION (Weeks 5-8)
Goal: Retrain gait pattern, improve foot pronation

PHASE 3: PERFORMANCE OPTIMIZATION (Weeks 9-12)
Goal: Restore running economy, build resilience
      ''',
      specificExercises: [
        Exercise(
          name: 'Hip Adductor Strengthening (Copenhagen Plank)',
          description: '''
1. Side plank position on forearm
2. Top leg elevated on bench/chair (hip height)
3. Bottom leg lifts to meet top leg
4. Hold 2-3 seconds at top
5. Control lowering

🎯 Why: Strengthens weak hip adductors to counter varus moment
      ''',
          sets: 3,
          reps: 10,
          frequency: 'Daily (5x/week)',
          progressionTimeline: '''
Week 1-2: Bent knee version, 8 reps
Week 3-4: Straight leg, 10 reps  
Week 5-8: Add 2-3kg ankle weight
Week 9-12: Single-leg eccentric focus
          ''',
        ),
        Exercise(
          name: 'VMO (Vastus Medialis) Activation',
          description: '''
1. Terminal knee extension with resistance band
2. Knee bent 20-30°, band around thigh
3. Squeeze knee straight, hold 3 seconds
4. Focus on inner quad contraction

🎯 Why: Strengthens medial knee stabilizer, protects lateral compartment
      ''',
          sets: 3,
          reps: 15,
          frequency: 'Daily (before runs)',
          progressionTimeline: '''
Week 1-2: Bodyweight only, feel VMO activation
Week 3-4: Light band resistance
Week 5-8: Medium band + single-leg balance
Week 9-12: Heavy band + plyometric integration
          ''',
        ),
        Exercise(
          name: 'Ankle Eversion Strengthening',
          description: '''
1. Seated, resistance band around forefoot
2. Turn foot outward (eversion) against resistance
3. Hold 2 seconds, control return
4. Focus on peroneal muscle engagement

🎯 Why: Builds ankle stability to allow controlled pronation
      ''',
          sets: 3,
          reps: 20,
          frequency: '4-5x/week',
          progressionTimeline: '''
Week 1-2: Light band, seated
Week 3-4: Medium band, standing single-leg
Week 5-8: Heavy band with balance challenge
Week 9-12: Explosive eversion with hop landings
          ''',
        ),
        Exercise(
          name: 'Gait Re-education: Midfoot Strike Drills',
          description: '''
1. Walk focusing on landing under hip (not laterally)
2. Progress to slow jog with midfoot landing
3. Use mirror or video feedback
4. 5-10 min sessions

🎯 Why: Retrains landing pattern to reduce lateral loading
      ''',
          sets: 1,
          reps: 0,
          frequency: '3x/week (during easy runs)',
          progressionTimeline: '''
Week 1-2: Walking drills only
Week 3-4: Walk-jog intervals, focus on foot placement
Week 5-8: 50% of easy runs with focus
Week 9-12: Natural integration, periodic check-ins
          ''',
        ),
      ],
      footwearRecommendation: '''
🥾 FOOTWEAR STRATEGY FOR BOW LEGS:

❌ AVOID:
• Stability/motion-control shoes (worsen supination)
• Minimalist shoes (need cushioning for lateral stress)
• High-drop shoes (>10mm, reduces ankle mobility)

✅ RECOMMENDED:
• Neutral cushioned shoes (8-10mm drop)
• Moderate arch support (not high)
• Slight lateral wedging (orthotic consultation)
• Examples: 
  - Brooks Ghost (neutral, cushioned)
  - Nike Pegasus (balanced platform)
  - Asics Nimbus (high cushion, neutral)

🔧 CUSTOM ORTHOTIC CONSIDERATION:
• If severe (>10° varus): Lateral heel wedge (3-5mm)
• Medial arch support to encourage pronation
• Consult podiatrist for gait analysis

⏱️ TIMELINE:
• Weeks 1-4: Focus on cushioning (protect lateral structures)
• Weeks 5-8: Introduce neutral shoes with exercises
• Weeks 9-12: Consider orthotic if not improving
      ''',
      terrainModifications: '''
🏞️ TERRAIN STRATEGY FOR BOW LEGS:

⚠️ AVOID (First 4-6 Weeks):
• Cambered roads (lateral tilt worsens varus stress)
• Rocky/uneven trails (lateral ankle sprains)
• Steep downhills (increased lateral knee loading)
• Hard surfaces (concrete) - use track or soft trails

✅ OPTIMAL TERRAIN:
• Flat, even surfaces (track, treadmill)
• Grass or synthetic turf (shock absorption)
• Indoor track (consistent surface)
• Slight inclines OK (uphill reduces impact)

📅 PROGRESSION:
Week 1-4: 100% flat, soft surfaces only
Week 5-8: Introduce gentle trails, avoid cambered roads
Week 9-12: Progressive return to varied terrain
Week 12+: Full terrain variety with proper footwear

🏃 TRAINING MODIFICATIONS:
• Reduce weekly mileage by 20-30% during correction phase
• Avoid speed work until Week 8+ (high lateral forces)
• Cross-train with swimming/cycling (non-weight-bearing)
• Gradual return: Add 10% mileage per week after Week 6
      ''',
      forceVectors: ForceVectorData.bowLegs,
      economyImpact: RunningEconomyImpact.bowLegs,
      musclePatterns: [
        const MuscleActivationPattern(
          muscleName: 'Tensor Fasciae Latae (TFL)',
          normalActivation: 40.0,
          pathologicalActivation: 80.0,
          status: 'overactive',
        ),
        const MuscleActivationPattern(
          muscleName: 'Peroneals',
          normalActivation: 50.0,
          pathologicalActivation: 90.0,
          status: 'overactive',
        ),
        const MuscleActivationPattern(
          muscleName: 'Hip Adductors',
          normalActivation: 60.0,
          pathologicalActivation: 30.0,
          status: 'underactive',
        ),
      ],
    );
  }
  
  /// Detect KNOCK KNEES (Genu Valgum) - Knees angle inward
  /// 
  /// Research-Based Detection Criteria (GaitDetectionThresholds.knockKnees):
  /// - Hip abduction <20 reps: +0.35 (weak glute medius)
  /// - Balance <15 sec: +0.30 (poor stability)
  /// - Knee flexion gap >8cm: +0.15 (tracking issue)
  /// - Patellofemoral pain history: +0.20
  /// - Threshold: 0.50 confidence to detect
  static GaitPathology? _analyzeKnockKnees(Map<String, dynamic> a) {
    double confidence = 0.0;
    String severity = 'Mild';
    
    // Use research-based thresholds
    final thresholds = GaitDetectionThresholds.knockKnees;
    
    // Check hip abduction strength (key indicator)
    int hipAbduction = a['hip_abduction_reps'] ?? 20;
    if (hipAbduction < ROMStandards.hipAbductionHigh) {
      confidence += thresholds['hipAbductionLow']!;
    }
    
    // Check single-leg balance (knock knees have poor stability)
    int balance = a['balance_test_seconds'] ?? 15;
    if (balance < ROMStandards.balanceHigh) {
      confidence += thresholds['balanceLow']!;
    }
    
    // Check knee flexion (knock knees often have tracking issues)
    double kneeFlexion = a['knee_flexion_gap_cm'] ?? 5.0;
    if (kneeFlexion > 8) {
      confidence += thresholds['kneeFlexionGap']!;
    }
    
    // Check injury history
    String injuryHistory = (a['previous_injuries'] ?? '').toLowerCase();
    if (injuryHistory.contains('patellofemoral') || 
        injuryHistory.contains('medial knee') ||
        injuryHistory.contains('pfps') ||
        injuryHistory.contains('runner\'s knee')) {
      confidence += thresholds['injuryHistory']!;
    }
    
    if (confidence < thresholds['threshold']!) return null;
    
    if (confidence >= 0.8) {
      severity = 'Severe';
    } else if (confidence >= 0.65) {
      severity = 'Moderate';
    }
    
    return GaitPathology(
      type: 'knock_knees',
      severity: severity,
      confidenceLevel: confidence,
      mechanismDescription: '''
🦵 KNOCK KNEES (Genu Valgum) BIOMECHANICS:

📐 STRUCTURAL ALIGNMENT:
• Knees angle inward when standing
• Reduced medial knee joint space
• Tibiofemoral angle: >5-10° valgus deviation
• Q-angle increased (normal 15°, knock knees 20°+)
• Weight-bearing line passes medial to knee center

🏃 RUNNING GAIT IMPACT:

1. HEEL STRIKE PHASE:
   • Excessive foot pronation (arch collapse)
   • Medial heel strike pattern
   • Rapid pronation velocity (+40% faster)
   • Ankle eversion increases medial knee stress

2. MIDSTANCE PHASE:
   • Dynamic knee valgus (knee caves inward)
   • Medial knee compartment compression
   • Patella tracks laterally (misalignment)
   • Hip adduction increases (weak glute medius)
   • Trendelenburg gait pattern (hip drop on stance side)

3. PUSH-OFF PHASE:
   • Delayed supination (foot stays pronated)
   • Reduced propulsive force (-15%)
   • Medial tibialis posterior overload
   • Hallux valgus stress (big toe)

⚡ FORCE VECTOR ANALYSIS:
• Ground reaction force: 2.5-3.0x body weight
• 65-75% concentrated on medial knee compartment (normal: 50%)
• Valgus moment at knee: +45% compared to neutral
• Patellofemoral joint stress: +60% (lateral facet)
• Q-angle increases from 15° to 20-25° during stance

💪 MUSCLE ACTIVATION PATTERNS:
• Overactive: Hip adductors, TFL (tensor fasciae latae)
• Underactive: Glute medius, glute maximus, VMO
• Compensation: Lateral trunk lean away from stance leg
• Energy cost: +10-15% compared to neutral alignment
• Delayed glute medius activation: 50-100ms late
      ''',
      associatedInjuries: [
        'Patellofemoral Pain Syndrome (PFPS) - "Runner\'s Knee" (+70% risk)',
        'Medial Knee Osteoarthritis (+55% risk)',
        'Iliotibial Band Syndrome (+50% risk)',
        'Pes Anserine Bursitis (+45% risk)',
        'Posterior Tibial Tendinopathy (+40% risk)',
        'Medial Tibial Stress Syndrome - "Shin Splints" (+50% risk)',
        'Plantar Fasciitis (+35% risk)',
        'Achilles Tendinopathy (+30% risk)',
      ],
      biomechanicalImpacts: [
        '🔴 Running Economy: -10 to -15% efficiency loss',
        '🔴 Stride Length: Reduced by 8-12%',
        '🔴 Ground Contact Time: +20-25ms',
        '🔴 Cadence: Increases +8-10 steps/min',
        '🔴 Vertical Oscillation: +3-4cm',
        '🔴 Propulsive Force: -15 to -20% push-off power',
      ],
      correctiveStrategy: '''
🎯 4-PHASE CORRECTION STRATEGY:

PHASE 1: GLUTE ACTIVATION & STABILIZATION (Weeks 1-3)
Goal: Wake up dormant glute medius, reduce Trendelenburg pattern

PHASE 2: NEUROMUSCULAR CONTROL (Weeks 4-6)
Goal: Integrate glute strength into functional movements

PHASE 3: RUNNING MECHANICS RETRAINING (Weeks 7-10)
Goal: Transfer strength to running gait, reduce compensation patterns

PHASE 4: PERFORMANCE RESTORATION (Weeks 11-16)
Goal: Full training volume, maintain corrected mechanics
      ''',
      specificExercises: [
        Exercise(
          name: 'Clamshells (Glute Medius Activation)',
          description: '''
1. Side-lying, hips flexed 45°, knees bent 90°
2. Keep feet together, lift top knee
3. Hold 2 seconds at top
4. Control lowering, NO hip rocking

🎯 Why: Isolates glute medius (primary stabilizer for knock knees)
      ''',
          sets: 3,
          reps: 20,
          frequency: 'Daily (7x/week)',
          progressionTimeline: '''
Week 1-2: Bodyweight, perfect form, 15 reps
Week 3-4: Light resistance band, 20 reps
Week 5-6: Medium band, 25 reps + 10 sec hold
Week 7-10: Heavy band, 30 reps
          ''',
        ),
        Exercise(
          name: 'Single-Leg Deadlift',
          description: '''
1. Stand on one leg, slight knee bend
2. Hinge at hip, reach opposite hand to foot
3. Keep hips LEVEL
4. Return using glute

🎯 Why: Functional strength + balance + hip stability
      ''',
          sets: 3,
          reps: 12,
          frequency: '5x/week',
          progressionTimeline: '''
Week 1-3: Bodyweight, hand to shin
Week 4-6: Hold 5-10kg weight
Week 7-10: 10-15kg weight, slow eccentric
          ''',
        ),
      ],
      footwearRecommendation: '''
🥾 FOOTWEAR STRATEGY FOR KNOCK KNEES:

✅ RECOMMENDED:
• Stability shoes (medial post to control pronation)
• Brooks Adrenaline GTS
• Asics Gel-Kayano
• New Balance 860
      ''',
      terrainModifications: '''
🏞️ TERRAIN STRATEGY:

⚠️ AVOID (First 6-8 Weeks):
• Cambered roads
• Technical trails
• Steep downhills

✅ OPTIMAL:
• Flat track or treadmill
• Synthetic turf
      ''',
      forceVectors: ForceVectorData.knockKnees,
      economyImpact: RunningEconomyImpact.knockKnees,
      musclePatterns: [
        const MuscleActivationPattern(
          muscleName: 'Hip Adductors',
          normalActivation: 40.0,
          pathologicalActivation: 85.0,
          status: 'overactive',
        ),
        const MuscleActivationPattern(
          muscleName: 'Tensor Fasciae Latae (TFL)',
          normalActivation: 40.0,
          pathologicalActivation: 80.0,
          status: 'overactive',
        ),
        const MuscleActivationPattern(
          muscleName: 'Glute Medius',
          normalActivation: 60.0,
          pathologicalActivation: 35.0,
          status: 'underactive',
        ),
        const MuscleActivationPattern(
          muscleName: 'Glute Medius',
          normalActivation: 60.0,
          pathologicalActivation: 60.0,
          status: 'delayed',
          delayMs: 75,
        ),
      ],
    );
  }
  
  /// Detect OVERPRONATION - Excessive inward ankle roll
  /// 
  /// Research-Based Detection Criteria (GaitDetectionThresholds.overpronation):
  /// - Ankle dorsiflexion <9cm: +0.25 (tight calves)
  /// - Hip abduction <20 reps: +0.30 (weak hips)
  /// - Core strength <40 sec: +0.20 (proximal instability)
  /// - Plantar fasciitis/PTT/Achilles history: +0.25
  /// - Threshold: 0.50 confidence to detect
  static GaitPathology? _analyzeOverpronation(Map<String, dynamic> a) {
    double confidence = 0.0;
    String severity = 'Mild';
    
    // Use research-based thresholds
    final thresholds = GaitDetectionThresholds.overpronation;
    
    double ankleDorsi = a['ankle_dorsiflexion_cm'] ?? 10.0;
    if (ankleDorsi < ROMStandards.ankleDorsiflexionHigh) {
      confidence += thresholds['ankleDorsiflexionLow']!;
    }
    
    int hipAbduction = a['hip_abduction_reps'] ?? 20;
    if (hipAbduction < ROMStandards.hipAbductionHigh) {
      confidence += thresholds['hipAbductionLow']!;
    }
    
    int plank = a['plank_hold_seconds'] ?? 45;
    if (plank < 40) {
      confidence += thresholds['coreStrength']!;
    }
    
    String injuryHistory = (a['previous_injuries'] ?? '').toLowerCase();
    if (injuryHistory.contains('plantar fasciitis') || 
        injuryHistory.contains('posterior tibial') ||
        injuryHistory.contains('achilles') ||
        injuryHistory.contains('shin splints')) {
      confidence += thresholds['injuryHistory']!;
    }
    
    if (confidence < thresholds['threshold']!) return null;
    
    if (confidence >= 0.8) {
      severity = 'Severe';
    } else if (confidence >= 0.65) {
      severity = 'Moderate';
    }
    
    return GaitPathology(
      type: 'overpronation',
      severity: severity,
      confidenceLevel: confidence,
      mechanismDescription: '''
👣 OVERPRONATION BIOMECHANICS:

📐 FOOT MECHANICS:
• Excessive inward ankle roll after heel strike
• Arch collapses >10-15° (normal: 4-8°)
• Rapid pronation velocity
• Delayed supination during push-off
      ''',
      associatedInjuries: [
        'Plantar Fasciitis (+60% risk)',
        'Posterior Tibial Tendon Dysfunction (+55% risk)',
        'Achilles Tendinopathy (+50% risk)',
        'Shin Splints (+55% risk)',
      ],
      biomechanicalImpacts: [
        '🔴 Running Economy: -8 to -10% efficiency loss',
        '🔴 Propulsive Force: -12 to -18%',
        '🔴 Ground Contact Time: +15-20ms',
      ],
      correctiveStrategy: '''
🎯 3-PHASE CORRECTION:

PHASE 1: FOOT-ANKLE STABILITY (Weeks 1-4)
PHASE 2: PROXIMAL CONTROL (Weeks 5-8)
PHASE 3: GAIT INTEGRATION (Weeks 9-12)
      ''',
      specificExercises: [
        Exercise(
          name: 'Short Foot Exercise',
          description: '''
1. Pull arch up WITHOUT curling toes
2. Hold 5 seconds

🎯 Why: Strengthens intrinsic foot muscles
      ''',
          sets: 3,
          reps: 15,
          frequency: 'Daily',
          progressionTimeline: 'Week 1-2: Seated, 10 reps\nWeek 3-4: Standing, 15 reps',
        ),
      ],
      footwearRecommendation: '''
✅ RECOMMENDED:
• Stability shoes with medial post
• Brooks Adrenaline GTS
• Asics Gel-Kayano
      ''',
      terrainModifications: '''
⚠️ AVOID: Cambered roads, soft surfaces
✅ OPTIMAL: Flat track, treadmill
      ''',
      forceVectors: ForceVectorData.overpronation,
      economyImpact: RunningEconomyImpact.overpronation,
      musclePatterns: [
        const MuscleActivationPattern(
          muscleName: 'Peroneals',
          normalActivation: 50.0,
          pathologicalActivation: 85.0,
          status: 'overactive',
        ),
        const MuscleActivationPattern(
          muscleName: 'Tibialis Posterior',
          normalActivation: 70.0,
          pathologicalActivation: 45.0,
          status: 'underactive',
        ),
      ],
    );
  }
  
  /// Detect UNDERPRONATION (Supination)
  static GaitPathology? _analyzeUnderpronation(Map<String, dynamic> a) {
    double confidence = 0.0;
    String severity = 'Mild';
    
    double ankleDorsi = a['ankle_dorsiflexion_cm'] ?? 10.0;
    if (ankleDorsi < 8) {
      confidence += 0.35;
    }
    
    int balance = a['balance_test_seconds'] ?? 15;
    if (balance < 12) {
      confidence += 0.25;
    }
    
    double hamstring = a['hamstring_flexibility_cm'] ?? 0.0;
    if (hamstring < -5) {
      confidence += 0.15;
    }
    
    String injuryHistory = (a['injury_history'] ?? '').toLowerCase();
    if (injuryHistory.contains('stress fracture') || 
        injuryHistory.contains('ankle sprain') ||
        injuryHistory.contains('metatarsal') ||
        injuryHistory.contains('lateral')) {
      confidence += 0.25;
    }
    
    if (confidence < 0.5) return null;
    
    if (confidence >= 0.8) {
      severity = 'Severe';
    } else if (confidence >= 0.65) {
      severity = 'Moderate';
    }
    
    return GaitPathology(
      type: 'underpronation',
      severity: severity,
      confidenceLevel: confidence,
      mechanismDescription: '''
👣 UNDERPRONATION (SUPINATION) BIOMECHANICS:

📐 FOOT MECHANICS:
• Insufficient inward ankle roll (<4° eversion)
• High, rigid arch (pes cavus)
• Foot stays supinated throughout stance
• Reduced shock absorption
• Excessive lateral foot loading
      ''',
      associatedInjuries: [
        'Lateral Ankle Sprains (+70% risk)',
        'Stress Fractures (Metatarsals 4-5) (+60% risk)',
        'Peroneal Tendinopathy (+50% risk)',
        'IT Band Syndrome (+45% risk)',
      ],
      biomechanicalImpacts: [
        '🔴 Running Economy: -10 to -12% efficiency loss',
        '🔴 Impact Shock: +30-40%',
        '🔴 Vertical Oscillation: +3-5cm',
      ],
      correctiveStrategy: '''
🎯 3-PHASE CORRECTION:

PHASE 1: MOBILITY & FLEXIBILITY (Weeks 1-4)
PHASE 2: PROPRIOCEPTION & CONTROL (Weeks 5-8)
PHASE 3: GAIT ADAPTATION (Weeks 9-12)
      ''',
      specificExercises: [
        Exercise(
          name: 'Aggressive Calf Stretching',
          description: '''
1. Face wall, toes 10cm from wall
2. Lunge knee forward to touch wall
3. HOLD 30 seconds

🎯 Why: Tight calves = rigid ankle = supination
      ''',
          sets: 3,
          reps: 5,
          frequency: 'DAILY (2x per day)',
          progressionTimeline: 'Week 1-2: 5cm from wall\nWeek 3-4: 8cm from wall',
        ),
      ],
      footwearRecommendation: '''
✅ RECOMMENDED:
• Neutral shoes with MAXIMUM CUSHIONING
• Brooks Glycerin
• Asics Gel-Nimbus
• Hoka Clifton
      ''',
      terrainModifications: '''
⚠️ AVOID: Hard concrete, rocky trails
✅ OPTIMAL: Synthetic track, treadmill, grass
      ''',
      forceVectors: ForceVectorData.underpronation,
      economyImpact: RunningEconomyImpact.underpronation,
      musclePatterns: [
        const MuscleActivationPattern(
          muscleName: 'Ankle Stabilizers',
          normalActivation: 60.0,
          pathologicalActivation: 90.0,
          status: 'overactive',
        ),
        const MuscleActivationPattern(
          muscleName: 'Gastrocnemius',
          normalActivation: 70.0,
          pathologicalActivation: 95.0,
          status: 'overactive',
        ),
      ],
    );
  }
}
