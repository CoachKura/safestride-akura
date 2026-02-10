// AISRI Calculator Service
//
// Calculates the Athlete Injury Susceptibility and Readiness Index (AISRI)
// based on 6 core pillars:
// 1. Adaptability - Training experience and frequency
// 2. Injury Risk - Current pain and injury history
// 3. Fatigue - Training intensity and volume
// 4. Recovery - Sleep quality and stress levels
// 5. Intensity - Training intensity relative to fitness level
// 6. Consistency - Training frequency and regularity

class AISRICalculator {
  /// Calculate AISRI score from assessment data
  ///
  /// Returns a map containing:
  /// - aisri_score: Overall score (0-100)
  /// - risk_level: 'Low', 'Moderate', or 'High'
  /// - pillar_scores: Map of individual pillar scores
  static Map<String, dynamic> calculateScore(Map<String, dynamic> assessment) {
    // Calculate each of the 6 pillars (0-100 points each)
    int adaptability = _calculateAdaptability(assessment);
    int injuryRisk = _calculateInjuryRisk(assessment);
    int fatigue = _calculateFatigue(assessment);
    int recovery = _calculateRecovery(assessment);
    int intensity = _calculateIntensity(assessment);
    int consistency = _calculateConsistency(assessment);

    // Total score is the average of all 6 pillars (0-100)
    int totalScore = ((adaptability +
                injuryRisk +
                fatigue +
                recovery +
                intensity +
                consistency) /
            6)
        .round();

    // Determine risk level based on total score
    String riskLevel;
    if (totalScore >= 80) {
      riskLevel = 'Low';
    } else if (totalScore >= 60) {
      riskLevel = 'Moderate';
    } else {
      riskLevel = 'High';
    }

    return {
      'aisri_score': totalScore,
      'risk_level': riskLevel,
      'pillar_adaptability': adaptability,
      'pillar_injury_risk': injuryRisk,
      'pillar_fatigue': fatigue,
      'pillar_recovery': recovery,
      'pillar_intensity': intensity,
      'pillar_consistency': consistency,
    };
  }

  /// Pillar 1: Adaptability
  /// Based on years of running experience, training frequency, and movement efficiency
  ///
  /// Higher scores indicate better adaptation to training stress
  static int _calculateAdaptability(Map<String, dynamic> a) {
    int yearsRunning = a['years_running'] ?? 0;
    String trainingFreq = a['training_frequency'] ?? '1-2 days/week';
    String shoulderRotation = a['shoulder_internal_rotation'] ?? 'Lower back';

    int score = 50; // Base score

    // Experience bonus (0-30 points)
    // More years = better adaptation
    score += (yearsRunning * 2).clamp(0, 30);

    // Training frequency bonus (0-20 points)
    if (trainingFreq.contains('7+')) {
      score += 20;
    } else if (trainingFreq.contains('5-6')) {
      score += 15;
    } else if (trainingFreq.contains('3-4')) {
      score += 10;
    } else {
      score += 5;
    }

    // Movement efficiency (0-10 points)
    // Good shoulder mobility indicates overall movement quality
    if (shoulderRotation == 'Upper back' ||
        shoulderRotation == 'Between shoulder blades') {
      score += 10; // Excellent mobility
    } else if (shoulderRotation == 'Mid-back') {
      score += 5; // Good mobility
    }

    return score.clamp(0, 100);
  }

  /// Pillar 2: Injury Risk
  /// Based on pain, injury history, ALL lower body ROM tests, balance, and core
  ///
  /// Higher scores indicate LOWER injury risk (better condition)
  static int _calculateInjuryRisk(Map<String, dynamic> a) {
    // Pain & history
    int currentPain = a['current_pain'] ?? 0;
    int monthsInjuryFree = a['months_injury_free'] ?? 0;

    // Physical tests
    double ankleDorsiflexion = a['ankle_dorsiflexion_cm'] ?? 10.0;
    double kneeFlexionGap = a['knee_flexion_gap_cm'] ?? 5.0;
    String kneeStrength = a['knee_extension_strength'] ?? 'Moderate (45-90°)';
    int hipFlexion = a['hip_flexion_angle'] ?? 110;
    int hipAbduction = a['hip_abduction_reps'] ?? 20;
    double hamstringFlex = a['hamstring_flexibility_cm'] ?? 0.0;
    int balance = a['balance_test_seconds'] ?? 15;
    int plank = a['plank_hold_seconds'] ?? 45;

    int score = 100; // Start high (low risk)

    // Pain penalty
    score -= (currentPain * 8);

    // Injury-free bonus
    score += (monthsInjuryFree * 2).clamp(0, 30);

    // Ankle dorsiflexion (research-validated)
    if (ankleDorsiflexion < 7) {
      score -= 20;
    } else if (ankleDorsiflexion < 9) {
      score -= 15;
    } else if (ankleDorsiflexion < 12) {
      score -= 5;
    } else {
      score += 5;
    }

    // Knee flexion
    if (kneeFlexionGap > 15) {
      score -= 15; // Very tight hamstrings
    } else if (kneeFlexionGap > 10) {
      score -= 10;
    } else if (kneeFlexionGap > 5) {
      score -= 5;
    }

    // Knee strength
    if (kneeStrength == 'Cannot perform') {
      score -= 20;
    } else if (kneeStrength == 'Shallow (<45°)') {
      score -= 10;
    } else if (kneeStrength == 'Deep (>90°)') {
      score += 5;
    }

    // Hip flexion
    if (hipFlexion < 100) {
      score -= 15;
    } else if (hipFlexion < 120) {
      score -= 5;
    }

    // Hip abduction
    if (hipAbduction < 15) {
      score -= 15;
    } else if (hipAbduction < 25) {
      score -= 5;
    }

    // Hamstring flexibility
    if (hamstringFlex > 10) {
      score -= 15; // Can't touch toes
    } else if (hamstringFlex > 5) {
      score -= 5;
    } else if (hamstringFlex < 0) {
      score += 5; // Past toes = good
    }

    // Balance
    if (balance < 10) {
      score -= 15;
    } else if (balance < 20) {
      score -= 5;
    }

    // Core strength
    if (plank < 30) {
      score -= 15;
    } else if (plank < 60) {
      score -= 5;
    } else if (plank > 90) {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  /// Pillar 3: Fatigue
  /// Based on training load, perceived fatigue, and postural fatigue indicators
  ///
  /// Higher scores indicate LESS fatigue (better recovery state)
  static int _calculateFatigue(Map<String, dynamic> a) {
    int trainingIntensity = a['training_intensity'] ?? 0;
    double weeklyMileage = a['weekly_mileage'] ?? 0;
    int perceivedFatigue = a['perceived_fatigue'] ?? 5;
    int neckRotation = a['neck_rotation_angle'] ?? 70;
    int shoulderFlexion = a['shoulder_flexion_angle'] ?? 170;

    int score = 80; // Base

    // Training load penalty
    score -= (trainingIntensity * 3);
    if (weeklyMileage > 50) {
      score -= 20;
    } else if (weeklyMileage > 30) {
      score -= 10;
    }

    // Perceived fatigue (strong indicator)
    score -= (perceivedFatigue * 5);

    // Postural fatigue indicators
    if (neckRotation < 60) {
      score -= 10; // Forward head posture
    }
    if (shoulderFlexion < 160) {
      score -= 10; // Rounded shoulders
    }

    return score.clamp(0, 100);
  }

  /// Pillar 4: Recovery
  /// Based on sleep, stress, resting heart rate, and breathing capacity
  ///
  /// Higher scores indicate better recovery capacity
  static int _calculateRecovery(Map<String, dynamic> a) {
    double sleepHours = a['sleep_hours'] ?? 0;
    int sleepQuality = a['sleep_quality'] ?? 0;
    int stressLevel = a['stress_level'] ?? 0;
    int restingHR = a['resting_heart_rate'] ?? 70;
    int shoulderAbduction = a['shoulder_abduction_angle'] ?? 170;

    int score = 0;

    // Sleep
    score += ((sleepHours - 4) * 8).round().clamp(0, 40);
    score += (sleepQuality * 4).clamp(0, 40);

    // Stress
    score -= (stressLevel * 2);

    // Cardiovascular recovery (resting HR)
    if (restingHR < 50) {
      score += 20;
    } else if (restingHR < 60) {
      score += 15;
    } else if (restingHR < 70) {
      score += 5;
    } else if (restingHR > 80) {
      score -= 10;
    }

    // Breathing capacity (shoulder mobility)
    if (shoulderAbduction < 160) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  /// Pillar 5: Intensity
  /// Based on training intensity, fitness level, strength capacity, and core endurance
  ///
  /// Higher scores indicate appropriate intensity for fitness level
  static int _calculateIntensity(Map<String, dynamic> a) {
    int trainingIntensity = a['training_intensity'] ?? 0;
    String fitnessLevel = a['fitness_level'] ?? 'Beginner';
    String kneeStrength = a['knee_extension_strength'] ?? 'Moderate (45-90°)';
    int plank = a['plank_hold_seconds'] ?? 45;

    int score = trainingIntensity * 10;

    // Fitness level adjustment
    switch (fitnessLevel) {
      case 'Elite':
        score = (score * 1.3).round();
        break;
      case 'Advanced':
        score = (score * 1.15).round();
        break;
      case 'Intermediate':
        score = (score * 1.0).round();
        break;
      case 'Beginner':
        score = (score * 0.8).round();
        break;
    }

    // Strength capacity
    if (kneeStrength == 'Deep (>90°)') {
      score += 15;
    } else if (kneeStrength == 'Moderate (45-90°)') {
      score += 5;
    } else if (kneeStrength == 'Cannot perform') {
      score -= 15;
    }

    // Core endurance
    if (plank > 90) {
      score += 10;
    } else if (plank < 30) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  /// Pillar 6: Consistency
  /// Based on training frequency, balance, and core strength
  ///
  /// Higher scores indicate more consistent training with good physical foundation
  static int _calculateConsistency(Map<String, dynamic> a) {
    String trainingFreq = a['training_frequency'] ?? '1-2 days/week';
    int balance = a['balance_test_seconds'] ?? 15;
    int plank = a['plank_hold_seconds'] ?? 45;

    int score = 0;

    // Training frequency
    if (trainingFreq.contains('7+')) {
      score += 50;
    } else if (trainingFreq.contains('5-6')) {
      score += 40;
    } else if (trainingFreq.contains('3-4')) {
      score += 25;
    } else {
      score += 10;
    }

    // Stability (indicates regular training)
    if (balance > 25) {
      score += 25;
    } else if (balance > 20) {
      score += 20;
    } else if (balance > 15) {
      score += 10;
    }

    // Core endurance (indicates consistent training)
    if (plank > 90) {
      score += 25;
    } else if (plank > 60) {
      score += 20;
    } else if (plank > 30) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Get a human-readable description of the risk level
  static String getRiskDescription(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return 'You have a low risk of injury. Your training is well-balanced and your body is adapting well.';
      case 'Moderate':
        return 'You have a moderate risk of injury. Pay attention to recovery and consider adjusting your training load.';
      case 'High':
        return 'You have a high risk of injury. Consider reducing training intensity, focusing on recovery, and consulting a professional.';
      default:
        return 'Risk level unknown. Complete your assessment to calculate your AISRI score.';
    }
  }

  /// Get a color representing the risk level
  static String getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low':
        return 'green';
      case 'Moderate':
        return 'orange';
      case 'High':
        return 'red';
      default:
        return 'grey';
    }
  }
}
