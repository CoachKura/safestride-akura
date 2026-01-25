/*
 * AKURA Performance Index (API) Calculator
 * Proprietary scoring system replacing VDOT for SafeStride platform
 */

export const calculateAkuraAPI = (athlete) => {
  // Base score from race times (0-100)
  let baseScore = 50; // Default for new athletes
  
  if (athlete.half_marathon_time) {
    // 1:24 HM (84 min) = 100 points; 2:30 HM (150 min) = 0 points
    baseScore = Math.max(0, (210 - athlete.half_marathon_time) / 1.5);
  } else if (athlete.ten_k_time) {
    // 40 min 10K = 83 points; 90 min 10K = 0 points
    baseScore = Math.max(0, (90 - athlete.ten_k_time) / 0.6);
  }
  
  // HR efficiency modifier (-20 to +20)
  const maxHR = 208 - (0.7 * (athlete.age || 30));
  const restingHR = athlete.resting_hr || 60;
  const hrReserve = maxHR - restingHR;
  const hrModifier = (hrReserve - 100) / 20; // ±5 points typical
  
  // Injury penalty (-10 per active injury)
  const injuryPenalty = (athlete.injuries?.length || 0) * -10;
  
  // Chennai climate adaptation bonus (+5 for locals)
  const climateBonus = athlete.location === 'Chennai' ? 5 : 0;
  
  // Consistency bonus (streak/completion rate)
  const consistencyBonus = (athlete.completion_rate || 0) > 0.8 ? 5 : 0;
  
  // Calculate final API score (0-100)
  const finalAPI = Math.max(0, Math.min(100, 
    baseScore + hrModifier + injuryPenalty + climateBonus + consistencyBonus
  ));
  
  return Math.round(finalAPI);
};

/**
 * Get reference paces based on API score (min/km)
 */
export const getReferencePaces = (apiScore) => {
  if (apiScore >= 85) {
    return {
      easy: { min: 5.5, max: 6.0 },
      tempo: { min: 4.0, max: 4.5 },
      intervals: { min: 3.5, max: 4.0 }
    };
  } else if (apiScore >= 70) {
    return {
      easy: { min: 6.0, max: 6.5 },
      tempo: { min: 4.5, max: 5.0 },
      intervals: { min: 4.0, max: 4.5 }
    };
  } else if (apiScore >= 50) {
    return {
      easy: { min: 6.5, max: 7.5 },
      tempo: { min: 5.0, max: 6.0 },
      intervals: { min: 4.5, max: 5.5 }
    };
  } else {
    return {
      easy: { min: 7.5, max: 9.0 },
      tempo: { min: 6.0, max: 7.5 },
      intervals: { min: 5.5, max: 7.0 }
    };
  }
};

/**
 * Calculate HR zones using Inbar formula
 */
export const calculateHRZones = (age, restingHR = 60) => {
  const maxHR = Math.round(208 - (0.7 * age));
  return {
    zone1: { 
      min: Math.round(maxHR * 0.60), 
      max: Math.round(maxHR * 0.70), 
      name: 'Recovery',
      color: '#10B981' // Green
    },
    zone2: { 
      min: Math.round(maxHR * 0.70), 
      max: Math.round(maxHR * 0.80), 
      name: 'Aerobic Base',
      color: '#3B82F6' // Blue
    },
    zone3: { 
      min: Math.round(maxHR * 0.80), 
      max: Math.round(maxHR * 0.87), 
      name: 'Tempo (Target Zone)',
      color: '#F59E0B' // Orange
    },
    zone4: { 
      min: Math.round(maxHR * 0.87), 
      max: Math.round(maxHR * 0.93), 
      name: 'VO2max',
      color: '#EF4444' // Red
    },
    zone5: { 
      min: Math.round(maxHR * 0.93), 
      max: maxHR, 
      name: 'Anaerobic',
      color: '#DC2626' // Dark Red
    },
    maxHR,
    restingHR
  };
};

/**
 * Get API category label
 */
export const getAPICategory = (apiScore) => {
  if (apiScore >= 85) return { label: 'Elite', color: '#DC2626' };
  if (apiScore >= 70) return { label: 'Advanced', color: '#F59E0B' };
  if (apiScore >= 50) return { label: 'Intermediate', color: '#3B82F6' };
  return { label: 'Beginner', color: '#10B981' };
};
