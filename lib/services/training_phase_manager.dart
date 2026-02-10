import 'dart:math';

/// Training Phase Manager - Tracks 0-5000km Economical Runner Roadmap
/// Manages 6-phase progression with zone distribution
class TrainingPhaseManager {
  /// Get current training phase based on total km run
  static Map<String, dynamic> getCurrentPhase(double totalKmRun) {
    if (totalKmRun < 800) {
      return _getPhase1BaseBuilding(totalKmRun);
    } else if (totalKmRun < 1600) {
      return _getPhase2AerobicDevelopment(totalKmRun);
    } else if (totalKmRun < 2400) {
      return _getPhase3ThresholdFocus(totalKmRun);
    } else if (totalKmRun < 3200) {
      return _getPhase4IntervalTraining(totalKmRun);
    } else if (totalKmRun < 4000) {
      return _getPhase5PeakPerformance(totalKmRun);
    } else {
      return _getPhase6TaperRecovery(totalKmRun);
    }
  }

  /// Phase 1: Base Building (0-800 km) - Weeks 1-16
  static Map<String, dynamic> _getPhase1BaseBuilding(double currentKm) {
    return {
      'phase_number': 1,
      'phase_name': 'Base Building',
      'km_range': '0-800 km',
      'weeks': '1-16',
      'current_km': currentKm,
      'progress_percent': ((currentKm / 800) * 100).clamp(0, 100).round(),
      'zone_distribution': {
        'AR': 20, // Active Recovery 20%
        'F': 75,  // Foundation 75% (PRIMARY)
        'EN': 5,  // Endurance 5%
        'TH': 0,
        'P': 0,
        'SP': 0,
      },
      'protocols': ['START', 'ENGINE'],
      'weekly_structure': {
        'runs': 3,
        'strength': 3,
      },
      'focus': 'Building aerobic base and running economy',
      'description': 'Foundation phase with conversational pace running',
      'color': '#4A90E2',
    };
  }

  /// Phase 2: Aerobic Development (800-1600 km) - Weeks 17-32
  static Map<String, dynamic> _getPhase2AerobicDevelopment(double currentKm) {
    return {
      'phase_number': 2,
      'phase_name': 'Aerobic Development',
      'km_range': '800-1600 km',
      'weeks': '17-32',
      'current_km': currentKm,
      'progress_percent': (((currentKm - 800) / 800) * 100).clamp(0, 100).round(),
      'zone_distribution': {
        'AR': 10,
        'F': 65,  // Foundation still primary
        'EN': 15, // Endurance increased
        'TH': 10, // Threshold introduced
        'P': 0,
        'SP': 0,
      },
      'protocols': ['ENGINE', 'OXYGEN', 'ZONES'],
      'weekly_structure': {
        'runs': 4,
        'strength': 3,
      },
      'focus': 'Improving aerobic capacity and oxygen efficiency',
      'description': 'Introduce tempo runs and longer endurance work',
      'color': '#48D1CC',
    };
  }

  /// Phase 3: Threshold Focus (1600-2400 km) - Weeks 33-48
  static Map<String, dynamic> _getPhase3ThresholdFocus(double currentKm) {
    return {
      'phase_number': 3,
      'phase_name': 'Threshold Focus',
      'km_range': '1600-2400 km',
      'weeks': '33-48',
      'current_km': currentKm,
      'progress_percent': (((currentKm - 1600) / 800) * 100).clamp(0, 100).round(),
      'zone_distribution': {
        'AR': 15,
        'F': 55,  // Foundation reduced
        'EN': 0,
        'TH': 30, // Threshold becomes major focus
        'P': 0,
        'SP': 0,
      },
      'protocols': ['POWER', 'ZONES', 'STRENGTH'],
      'weekly_structure': {
        'runs': 4,
        'strength': 4,
      },
      'focus': 'Lactate threshold and race pace development',
      'description': 'Core zone training - sustained hard efforts',
      'color': '#FFA500',
    };
  }

  /// Phase 4: Interval Training (2400-3200 km) - Weeks 49-64
  static Map<String, dynamic> _getPhase4IntervalTraining(double currentKm) {
    return {
      'phase_number': 4,
      'phase_name': 'Interval Training',
      'km_range': '2400-3200 km',
      'weeks': '49-64',
      'current_km': currentKm,
      'progress_percent': (((currentKm - 2400) / 800) * 100).clamp(0, 100).round(),
      'zone_distribution': {
        'AR': 20,
        'F': 45,  // Foundation maintained
        'EN': 0,
        'TH': 0,
        'P': 35,  // Power zone introduced (if unlocked)
        'SP': 0,
      },
      'protocols': ['POWER', 'ZONES', 'STRENGTH'],
      'weekly_structure': {
        'runs': 5,
        'strength': 4,
      },
      'focus': 'VO2 max development through intervals',
      'description': 'High-intensity interval work with adequate recovery',
      'color': '#FF6B6B',
    };
  }

  /// Phase 5: Peak Performance (3200-4000 km) - Weeks 65-80
  static Map<String, dynamic> _getPhase5PeakPerformance(double currentKm) {
    return {
      'phase_number': 5,
      'phase_name': 'Peak Performance',
      'km_range': '3200-4000 km',
      'weeks': '65-80',
      'current_km': currentKm,
      'progress_percent': (((currentKm - 3200) / 800) * 100).clamp(0, 100).round(),
      'zone_distribution': {
        'AR': 30, // Increased recovery
        'F': 40,
        'EN': 0,
        'TH': 0,
        'P': 30,  // Power maintained
        'SP': 0,  // Speed work if unlocked
      },
      'protocols': ['LONG RUN', 'ZONES', 'STRENGTH'],
      'weekly_structure': {
        'runs': 5,
        'strength': 5,
      },
      'focus': 'Race preparation and peak fitness',
      'description': 'Sharpening phase with race-specific work',
      'color': '#9B59B6',
    };
  }

  /// Phase 6: Taper & Recovery (4000-5000 km) - Weeks 81-100
  static Map<String, dynamic> _getPhase6TaperRecovery(double currentKm) {
    return {
      'phase_number': 6,
      'phase_name': 'Taper & Recovery',
      'km_range': '4000-5000 km',
      'weeks': '81-100',
      'current_km': currentKm,
      'progress_percent': (((currentKm - 4000) / 1000) * 100).clamp(0, 100).round(),
      'zone_distribution': {
        'AR': 40, // Heavy recovery focus
        'F': 50,
        'EN': 10,
        'TH': 0,
        'P': 0,
        'SP': 0,
      },
      'protocols': ['START', 'ENGINE', 'LONG RUN'],
      'weekly_structure': {
        'runs': 3,
        'strength': 2,
      },
      'focus': 'Recovery and maintenance',
      'description': 'Reduced volume to peak for goal event',
      'color': '#87CEEB',
    };
  }

  /// Generate weekly workout schedule based on phase
  static List<Map<String, dynamic>> generateWeeklySchedule({
    required Map<String, dynamic> currentPhase,
    required List<String> allowedZones,
    required int aisriScore,
  }) {
    final weeklySchedule = <Map<String, dynamic>>[];
    final zoneDistribution = currentPhase['zone_distribution'] as Map<String, dynamic>;
    final weeklyStructure = currentPhase['weekly_structure'] as Map<String, dynamic>;
    final runsPerWeek = weeklyStructure['runs'] as int;

    // Assign zones to days based on distribution
    final zonesToAssign = <String>[];
    zoneDistribution.forEach((zone, percent) {
      if (percent > 0 && allowedZones.contains(zone)) {
        final numRuns = ((runsPerWeek * percent) / 100).ceil();
        for (var i = 0; i < numRuns; i++) {
          zonesToAssign.add(zone);
        }
      }
    });

    // Create weekly schedule
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    var zoneIndex = 0;

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      
      if (day == 'Monday' || day == 'Friday') {
        // Foundation runs
        weeklySchedule.add({
          'day': day,
          'workout_type': 'Run',
          'zone': 'F',
          'description': 'Foundation Run - Aerobic base building',
        });
      } else if (day == 'Tuesday') {
        // Endurance or Threshold
        final zone = zoneIndex < zonesToAssign.length ? zonesToAssign[zoneIndex++] : 'EN';
        weeklySchedule.add({
          'day': day,
          'workout_type': 'Run',
          'zone': zone,
          'description': _getZoneDescription(zone),
        });
      } else if (day == 'Wednesday' || day == 'Sunday') {
        // Active Recovery
        weeklySchedule.add({
          'day': day,
          'workout_type': 'Recovery',
          'zone': 'AR',
          'description': 'Active Recovery - Easy pace or rest',
        });
      } else if (day == 'Thursday') {
        // Strength Training
        weeklySchedule.add({
          'day': day,
          'workout_type': 'Strength',
          'zone': null,
          'description': 'Strength & Conditioning',
        });
      } else if (day == 'Saturday') {
        // Quality workout or long run
        final zone = zoneIndex < zonesToAssign.length ? zonesToAssign[zoneIndex++] : 'TH';
        weeklySchedule.add({
          'day': day,
          'workout_type': 'Quality',
          'zone': allowedZones.contains(zone) ? zone : 'F',
          'description': _getZoneDescription(zone),
        });
      }
    }

    return weeklySchedule;
  }

  static String _getZoneDescription(String zone) {
    switch (zone) {
      case 'AR':
        return 'Active Recovery - Very easy pace';
      case 'F':
        return 'Foundation - Conversational pace';
      case 'EN':
        return 'Endurance - Steady aerobic run';
      case 'TH':
        return 'Threshold - Comfortably hard pace';
      case 'P':
        return 'Power - High intensity intervals';
      case 'SP':
        return 'Speed - Sprint work';
      default:
        return 'Easy run';
    }
  }

  /// Calculate total distance needed for next phase
  static Map<String, dynamic> getNextPhaseMilestone(double currentKm) {
    if (currentKm < 800) {
      return {
        'next_phase': 'Aerobic Development',
        'km_remaining': (800 - currentKm).round(),
        'weeks_estimated': ((800 - currentKm) / 30).ceil(), // ~30km/week
      };
    } else if (currentKm < 1600) {
      return {
        'next_phase': 'Threshold Focus',
        'km_remaining': (1600 - currentKm).round(),
        'weeks_estimated': ((1600 - currentKm) / 35).ceil(),
      };
    } else if (currentKm < 2400) {
      return {
        'next_phase': 'Interval Training',
        'km_remaining': (2400 - currentKm).round(),
        'weeks_estimated': ((2400 - currentKm) / 40).ceil(),
      };
    } else if (currentKm < 3200) {
      return {
        'next_phase': 'Peak Performance',
        'km_remaining': (3200 - currentKm).round(),
        'weeks_estimated': ((3200 - currentKm) / 45).ceil(),
      };
    } else if (currentKm < 4000) {
      return {
        'next_phase': 'Taper & Recovery',
        'km_remaining': (4000 - currentKm).round(),
        'weeks_estimated': ((4000 - currentKm) / 40).ceil(),
      };
    } else {
      return {
        'next_phase': 'Goal Complete!',
        'km_remaining': max(0, (5000 - currentKm)).round(),
        'weeks_estimated': 0,
      };
    }
  }

  /// Get phase color
  static String getPhaseColor(int phaseNumber) {
    switch (phaseNumber) {
      case 1:
        return '#4A90E2'; // Blue
      case 2:
        return '#48D1CC'; // Turquoise
      case 3:
        return '#FFA500'; // Orange
      case 4:
        return '#FF6B6B'; // Red
      case 5:
        return '#9B59B6'; // Purple
      case 6:
        return '#87CEEB'; // Light blue
      default:
        return '#4A90E2';
    }
  }
}
