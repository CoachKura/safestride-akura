# AI-Powered Workout Push to Garmin Calendar 🤖➡️⌚

## Overview

This guide shows how SafeStride's AI/ML engine generates personalized workouts and automatically pushes them to Garmin Connect calendar, appearing on the athlete's watch as **"Today's Workout"** or **"Tomorrow's Workout"**.

---

## 🎯 Complete Workflow

```
SafeStride AI/ML Engine
         ↓
   (Analyzes athlete data)
   • Current VO2 Max: 37
   • AISRI Score: 73
   • Recovery Status: Poor (19)
   • Training Load: High (1.5 ratio)
   • Sleep: 5h 15m (insufficient)
   • Body Battery: 54
         ↓
   (Generates optimal workout)
   • Type: Easy Run (Zone EN)
   • Duration: 40 minutes
   • Target HR: 125-141 bpm
   • Instructions: Recovery run
         ↓
   (Pushes to Garmin API)
         ↓
Garmin Connect Calendar
         ↓
Athlete's Watch Display:
╔════════════════════════════╗
║   TODAY'S WORKOUT          ║
║   Easy Run - 40 min        ║
║   Zone EN: 125-141 bpm     ║
║   Tap to start             ║
╚════════════════════════════╝
```

---

## 🧠 AI/ML Workout Generation Logic

### Input Data from Garmin API

```dart
class AthleteProfile {
  // Fitness metrics
  final double vo2Max;              // 37 ml/kg/min
  final int lactateThresholdHR;     // 158 bpm
  final double lactateThresholdPace; // 6:40/km

  // Recovery metrics
  final int trainingReadiness;      // 19 (poor)
  final int bodyBattery;            // 54
  final int sleepScore;             // 60
  final int hrvMorning;             // 72ms
  final String hrvStatus;           // "balanced"

  // Training load
  final int acuteLoad;              // 349
  final int chronicLoad;            // 231
  final double loadRatio;           // 1.5 (high)
  final String trainingStatus;      // "unproductive"

  // Recent activity
  final double recentAveragePace;   // 9:09/km
  final double weeklyMileage;       // 23.12 km

  // Biomechanics (AISRI)
  final int aisriScore;             // 73
  final int avgCadence;             // 146 spm
  final int gct;                    // 290 ms
  final double verticalOscillation; // 7.3 cm
}
```

### AI Decision Engine

```dart
// lib/services/ai_workout_generator.dart
class AIWorkoutGenerator {

  static Future<WorkoutProtocol> generateDailyWorkout(
    String athleteId,
  ) async {
    // 1. Fetch all relevant data
    final profile = await _fetchAthleteProfile(athleteId);
    final metrics = await _fetchLatestMetrics(athleteId);
    final progressionPlan = await _fetchProgressionPlan(athleteId);

    // 2. Calculate readiness score
    final readiness = _calculateReadiness(profile);

    // 3. Determine workout intensity
    final intensity = _determineIntensity(
      readiness: readiness,
      trainingLoad: profile.loadRatio,
      sleepQuality: profile.sleepScore,
      bodyBattery: profile.bodyBattery,
    );

    // 4. Generate workout based on progression plan
    final workout = _generateWorkout(
      intensity: intensity,
      vo2Max: profile.vo2Max,
      lactateThreshold: profile.lactateThresholdHR,
      aisriScore: profile.aisriScore,
      currentPhase: progressionPlan.currentPhase,
    );

    // 5. Add biomechanics focus
    final enhancedWorkout = _addBiomechanicsCues(
      workout: workout,
      gct: profile.gct,
      cadence: profile.avgCadence,
      vo: profile.verticalOscillation,
    );

    return enhancedWorkout;
  }

  // ================================
  // READINESS CALCULATION
  // ================================

  static double _calculateReadiness(AthleteProfile profile) {
    var score = 100.0;

    // Sleep impact (30% weight)
    if (profile.sleepScore < 60) {
      score -= 30 * (1 - profile.sleepScore / 100);
    }

    // Body Battery impact (25% weight)
    if (profile.bodyBattery < 50) {
      score -= 25 * (1 - profile.bodyBattery / 100);
    }

    // Training Load impact (25% weight)
    if (profile.loadRatio > 1.3) {
      score -= 25 * (profile.loadRatio - 1.0);
    }

    // HRV status (20% weight)
    if (profile.hrvStatus == 'unbalanced' || profile.hrvStatus == 'low') {
      score -= 20;
    }

    return score.clamp(0, 100);
  }

  // ================================
  // INTENSITY DETERMINATION
  // ================================

  static WorkoutIntensity _determineIntensity({
    required double readiness,
    required double trainingLoad,
    required int sleepQuality,
    required int bodyBattery,
  }) {
    // Poor readiness → Easy workout
    if (readiness < 40 || bodyBattery < 30 || sleepQuality < 50) {
      return WorkoutIntensity.recovery;
    }

    // Low readiness → Moderate workout
    if (readiness < 60 || bodyBattery < 50) {
      return WorkoutIntensity.easy;
    }

    // High load ratio → Active recovery
    if (trainingLoad > 1.5) {
      return WorkoutIntensity.recovery;
    }

    // Good readiness → Training workout
    if (readiness >= 80 && bodyBattery >= 70) {
      return WorkoutIntensity.high;
    }

    // Default: Moderate intensity
    return WorkoutIntensity.moderate;
  }

  // ================================
  // WORKOUT GENERATION
  // ================================

  static WorkoutProtocol _generateWorkout({
    required WorkoutIntensity intensity,
    required double vo2Max,
    required int lactateThreshold,
    required int aisriScore,
    required TrainingPhase currentPhase,
  }) {
    switch (intensity) {
      case WorkoutIntensity.recovery:
        return _generateRecoveryRun(lactateThreshold);

      case WorkoutIntensity.easy:
        return _generateEasyRun(lactateThreshold, currentPhase);

      case WorkoutIntensity.moderate:
        return _generateBaseRun(lactateThreshold, vo2Max, currentPhase);

      case WorkoutIntensity.high:
        return _generateIntervalsWorkout(
          lactateThreshold,
          vo2Max,
          aisriScore,
          currentPhase,
        );
    }
  }

  // ================================
  // RECOVERY RUN
  // ================================

  static WorkoutProtocol _generateRecoveryRun(int lactateThresholdHR) {
    // Very easy pace, HR Zone 1-2
    final maxHR = 190; // Or calculate from athlete data
    final zone1Max = (maxHR * 0.65).round(); // 65% max HR

    return WorkoutProtocol(
      name: 'Recovery Run',
      type: WorkoutType.run,
      duration: Duration(minutes: 30),
      targetZone: TrainingZone.recovery,
      steps: [
        WorkoutStep(
          type: StepType.warmup,
          duration: Duration(minutes: 5),
          targetHRMin: (maxHR * 0.50).round(),
          targetHRMax: (maxHR * 0.60).round(),
          instructions: 'Walk to easy jog - feel loose',
        ),
        WorkoutStep(
          type: StepType.run,
          duration: Duration(minutes: 20),
          targetHRMin: (maxHR * 0.60).round(),
          targetHRMax: zone1Max,
          instructions: 'Easy conversational pace - focus on relaxation',
        ),
        WorkoutStep(
          type: StepType.cooldown,
          duration: Duration(minutes: 5),
          targetHRMin: (maxHR * 0.50).round(),
          targetHRMax: (maxHR * 0.60).round(),
          instructions: 'Easy jog to walk',
        ),
      ],
      description: 'Active recovery - keep it super easy today. '
          'Your body needs rest (readiness low). '
          'Focus: Relaxed form, no effort.',
    );
  }

  // ================================
  // ZONE TH INTERVALS (High Intensity)
  // ================================

  static WorkoutProtocol _generateIntervalsWorkout(
    int lactateThresholdHR,
    double vo2Max,
    int aisriScore,
    TrainingPhase phase,
  ) {
    // Threshold intervals: 4-6 repeats at LT HR
    final intervalCount = vo2Max >= 45 ? 6 : 4;
    final intervalDuration = Duration(minutes: 6);
    final recoveryDuration = Duration(minutes: 2);

    final steps = <WorkoutStep>[
      // Warm-up
      WorkoutStep(
        type: StepType.warmup,
        duration: Duration(minutes: 15),
        targetHRMin: (lactateThresholdHR * 0.65).round(),
        targetHRMax: (lactateThresholdHR * 0.75).round(),
        instructions: 'Gradual warm-up to working pace',
      ),
    ];

    // Add intervals
    for (int i = 0; i < intervalCount; i++) {
      // Work interval
      steps.add(WorkoutStep(
        type: StepType.interval,
        duration: intervalDuration,
        targetHRMin: (lactateThresholdHR * 0.95).round(),
        targetHRMax: (lactateThresholdHR * 1.02).round(),
        targetCadence: 165, // From AISRI guidelines
        instructions: 'Threshold effort - ${i + 1}/$intervalCount. '
            'Maintain cadence 165+, GCT < 280ms',
      ));

      // Recovery if not last interval
      if (i < intervalCount - 1) {
        steps.add(WorkoutStep(
          type: StepType.recovery,
          duration: recoveryDuration,
          targetHRMin: (lactateThresholdHR * 0.70).round(),
          targetHRMax: (lactateThresholdHR * 0.80).round(),
          instructions: 'Easy jog recovery',
        ));
      }
    }

    // Cool-down
    steps.add(WorkoutStep(
      type: StepType.cooldown,
      duration: Duration(minutes: 10),
      targetHRMin: 100,
      targetHRMax: 120,
      instructions: 'Easy jog to walk',
    ));

    return WorkoutProtocol(
      name: 'Threshold Intervals',
      type: WorkoutType.run,
      duration: Duration(
        minutes: 15 + // warmup
            (6 * intervalCount) + // work
            (2 * (intervalCount - 1)) + // recovery
            10, // cooldown
      ),
      targetZone: TrainingZone.threshold,
      steps: steps,
      description: 'Zone TH Intervals: $intervalCount x 6min @ LT. '
          'Builds threshold capacity. '
          'Focus: Maintain form, cadence 165+, GCT < 280ms',
    );
  }
}
```

---

## 📤 Push Workout to Garmin Calendar

### Garmin Workout API Endpoint

```dart
// lib/services/garmin_workout_push_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class GarminWorkoutPushService {
  static const String baseUrl = 'https://apis.garmin.com';

  // ================================
  // PUSH WORKOUT TO GARMIN CALENDAR
  // ================================

  static Future<void> pushWorkoutToGarmin({
    required String athleteId,
    required WorkoutProtocol workout,
    required DateTime scheduledDate,
  }) async {
    // 1. Get Garmin credentials
    final credentials = await _getGarminCredentials(athleteId);

    // 2. Convert SafeStride workout → Garmin FIT format
    final garminWorkout = _convertToGarminFormat(workout);

    // 3. Upload to Garmin Connect
    final workoutId = await _uploadWorkout(
      credentials: credentials,
      workout: garminWorkout,
    );

    // 4. Schedule workout on calendar
    await _scheduleWorkout(
      credentials: credentials,
      workoutId: workoutId,
      date: scheduledDate,
    );

    print('✅ Workout pushed to Garmin calendar: ${workout.name}');
    print('   Scheduled for: ${scheduledDate.toLocal()}');
    print('   Workout ID: $workoutId');
  }

  // ================================
  // CONVERT TO GARMIN FORMAT
  // ================================

  static Map<String, dynamic> _convertToGarminFormat(WorkoutProtocol workout) {
    return {
      'workoutName': workout.name,
      'description': workout.description,
      'sportType': _mapSportType(workout.type),
      'workoutSegments': workout.steps.map((step) {
        return {
          'segmentOrder': workout.steps.indexOf(step) + 1,
          'sportType': _mapSportType(workout.type),
          'workoutSteps': [
            {
              'type': _mapStepType(step.type),
              'stepOrder': 1,
              'intensity': _mapIntensity(step.type),
              'durationType': 'TIME',
              'durationValue': step.duration.inSeconds,
              'durationValueType': 'SECONDS',

              // Target Heart Rate
              if (step.targetHRMin != null && step.targetHRMax != null)
                'targetType': 'HEART_RATE',
              if (step.targetHRMin != null)
                'targetValueOne': step.targetHRMin,
              if (step.targetHRMax != null)
                'targetValueTwo': step.targetHRMax,

              // Target Cadence (if specified)
              if (step.targetCadence != null)
                'secondaryTargetType': 'CADENCE',
              if (step.targetCadence != null)
                'secondaryTargetValueOne': step.targetCadence - 5,
              if (step.targetCadence != null)
                'secondaryTargetValueTwo': step.targetCadence + 5,

              // Instructions
              'description': step.instructions,
            },
          ],
        };
      }).toList(),
    };
  }

  // ================================
  // UPLOAD WORKOUT
  // ================================

  static Future<int> _uploadWorkout({
    required GarminCredentials credentials,
    required Map<String, dynamic> workout,
  }) async {
    final url = Uri.parse('$baseUrl/workout-service/workout');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${credentials.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(workout),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['workoutId'] as int;
    } else {
      throw Exception('Failed to upload workout: ${response.statusCode}');
    }
  }

  // ================================
  // SCHEDULE WORKOUT ON CALENDAR
  // ================================

  static Future<void> _scheduleWorkout({
    required GarminCredentials credentials,
    required int workoutId,
    required DateTime date,
  }) async {
    final url = Uri.parse('$baseUrl/workout-service/schedule');

    final scheduleData = {
      'workoutId': workoutId,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${credentials.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(scheduleData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to schedule workout: ${response.statusCode}');
    }
  }

  // ================================
  // HELPER FUNCTIONS
  // ================================

  static String _mapSportType(WorkoutType type) {
    switch (type) {
      case WorkoutType.run:
        return 'RUNNING';
      case WorkoutType.bike:
        return 'CYCLING';
      default:
        return 'RUNNING';
    }
  }

  static String _mapStepType(StepType type) {
    switch (type) {
      case StepType.warmup:
        return 'WARMUP';
      case StepType.run:
      case StepType.interval:
        return 'INTERVAL';
      case StepType.recovery:
        return 'RECOVERY';
      case StepType.cooldown:
        return 'COOLDOWN';
      default:
        return 'INTERVAL';
    }
  }

  static String _mapIntensity(StepType type) {
    switch (type) {
      case StepType.warmup:
      case StepType.cooldown:
        return 'WARMUP';
      case StepType.recovery:
        return 'RECOVERY';
      case StepType.interval:
        return 'ACTIVE';
      default:
        return 'ACTIVE';
    }
  }
}
```

---

## 🤖 Automated Daily Workflow

### Background Service (Runs Daily at 8 PM)

```dart
// lib/services/daily_workout_scheduler.dart
class DailyWorkoutScheduler {

  // Run every day at 8 PM
  static Future<void> scheduleWorkoutsForAllAthletes() async {
    // 1. Get all active athletes
    final athletes = await Supabase.instance.client
        .from('profiles')
        .select('id, garmin_connected')
        .eq('garmin_connected', true)
        .eq('active', true);

    print('📅 Scheduling workouts for ${athletes.length} athletes...');

    // 2. For each athlete
    for (final athlete in athletes) {
      try {
        await _scheduleWorkoutForAthlete(athlete['id']);
      } catch (e) {
        print('❌ Error scheduling for ${athlete['id']}: $e');
      }
    }

    print('✅ Daily workout scheduling complete!');
  }

  static Future<void> _scheduleWorkoutForAthlete(String athleteId) async {
    // 1. Fetch latest data from Garmin
    await GarminSyncService.syncRecentData(athleteId);

    // 2. Generate tomorrow's workout
    final workout = await AIWorkoutGenerator.generateDailyWorkout(athleteId);

    // 3. Push to Garmin calendar
    final tomorrow = DateTime.now().add(Duration(days: 1));
    await GarminWorkoutPushService.pushWorkoutToGarmin(
      athleteId: athleteId,
      workout: workout,
      scheduledDate: tomorrow,
    );

    // 4. Store in SafeStride database
    await _saveWorkoutToDatabase(athleteId, workout, tomorrow);

    // 5. Send notification to athlete
    await _notifyAthlete(athleteId, workout);

    print('✅ Workout scheduled for athlete: $athleteId');
  }

  static Future<void> _saveWorkoutToDatabase(
    String athleteId,
    WorkoutProtocol workout,
    DateTime scheduledDate,
  ) async {
    await Supabase.instance.client.from('scheduled_workouts').insert({
      'athlete_id': athleteId,
      'workout_name': workout.name,
      'workout_type': workout.type.toString(),
      'target_zone': workout.targetZone.toString(),
      'duration_minutes': workout.duration.inMinutes,
      'steps': workout.steps.map((s) => s.toJson()).toList(),
      'description': workout.description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'garmin_synced': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> _notifyAthlete(
    String athleteId,
    WorkoutProtocol workout,
  ) async {
    // Send push notification
    await PushNotificationService.send(
      userId: athleteId,
      title: 'Tomorrow\'s Workout Ready! 💪',
      body: '${workout.name} - ${workout.duration.inMinutes} min',
      data: {
        'type': 'workout_scheduled',
        'workout_name': workout.name,
      },
    );
  }
}
```

### Setup Cron Job / Scheduled Task

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... other initialization

  // Schedule daily workout generation (8 PM every day)
  await Workmanager().registerPeriodicTask(
    'daily-workout-generation',
    'dailyWorkoutTask',
    frequency: Duration(hours: 24),
    initialDelay: _getNext8PM(),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  runApp(MyApp());
}

// Background task handler
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'dailyWorkoutTask':
        await DailyWorkoutScheduler.scheduleWorkoutsForAllAthletes();
        return true;
      default:
        return false;
    }
  });
}
```

---

## 📱 What Athlete Sees on Watch

### Garmin Watch Display

**Home Screen Widget**:

```
╔════════════════════════════════════════╗
║  TODAY'S WORKOUT                       ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║  📅 Threshold Intervals                ║
║  ⏱️  65 min • Zone TH                  ║
║  ❤️  145-164 bpm                       ║
║  🎯 6 x 6min @ Lactate Threshold       ║
║                                        ║
║  [Start Workout]                       ║
╚════════════════════════════════════════╝
```

**During Workout** (Garmin displays each step):

```
Step 1/14: Warm Up
├─ Target: 15:00
├─ HR: 118-133 bpm
└─ "Gradual warm-up to working pace"

Step 2/14: Interval 1/6
├─ Target: 6:00
├─ HR: 150-162 bpm
├─ Cadence: 160-170 spm
└─ "Threshold effort - maintain form"

Step 3/14: Recovery
├─ Target: 2:00
├─ HR: 110-127 bpm
└─ "Easy jog recovery"

... (continues through all steps)
```

---

## 🧪 Example Scenarios

### Scenario 1: Poor Recovery (Based on Your Data)

**Athlete Metrics**:

- Sleep: 5h 15m (score 60) ❌
- Body Battery: 54 ⚠️
- Training Readiness: 19 (poor) ❌
- Load Ratio: 1.5 (high) ⚠️
- HRV Status: Balanced ✓

**AI Decision**:

```dart
Readiness Score: 42/100
→ Intensity: RECOVERY
→ Workout: Easy 30min Run
→ Zone: EN (Recovery)
→ HR Target: 95-124 bpm
```

**Generated Workout**:

```
Recovery Run - 30 minutes
━━━━━━━━━━━━━━━━━━━━━━━━
Zone EN • Heart Rate: 95-124 bpm

Description:
Your body needs rest today - readiness is low (42/100).
Sleep was insufficient (5h 15m), training load is high.
Focus on active recovery, stay conversational.

Steps:
1. Warm-up (5 min): Walk to easy jog
2. Easy Run (20 min): HR 95-124, relaxed
3. Cool-down (5 min): Easy jog to walk

Biomechanics Focus:
✓ No specific targets - just feel loose
✓ Relax shoulders, arms, jaw
✓ Natural cadence, no forcing
```

**Pushed to Garmin** → Athlete sees on watch tomorrow morning

---

### Scenario 2: Good Recovery, Building Phase

**Athlete Metrics**:

- Sleep: 7h 45m (score 85) ✓
- Body Battery: 82 ✓
- Training Readiness: 78 (good) ✓
- Load Ratio: 1.1 (optimal) ✓
- VO2 Max: 37
- Current Phase: Threshold Work

**AI Decision**:

```dart
Readiness Score: 82/100
→ Intensity: HIGH
→ Workout: Zone TH Intervals
→ Target: Lactate Threshold (158 bpm)
```

**Generated Workout**:

```
Threshold Intervals - 65 minutes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Zone TH • Heart Rate: 150-162 bpm

Description:
Great recovery! Ready for quality work.
Building threshold capacity to improve VO2 Max (37→40).
6 repeats at lactate threshold pace.

Steps:
1. Warm-up (15 min): HR 102-118, gradual
2. Interval 1/6 (6 min): HR 150-162, Cadence 165+
3. Recovery (2 min): HR 110-127, easy jog
4. Interval 2/6 (6 min): HR 150-162, maintain form
... [continues]
13. Cool-down (10 min): HR 100-120

Biomechanics Focus:
✓ Maintain cadence 165+ spm
✓ Keep GCT < 280ms
✓ Vertical oscillation < 8cm
✓ Relaxed upper body
```

---

## 📊 Complete Database Schema

### scheduled_workouts table

```sql
CREATE TABLE scheduled_workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES auth.users(id) NOT NULL,

  -- Workout details
  workout_name TEXT NOT NULL,
  workout_type TEXT NOT NULL,          -- 'run', 'bike', etc.
  target_zone TEXT,                   -- 'EN', 'TH', 'P'
  duration_minutes INTEGER,
  steps JSONB,                        -- Array of workout steps
  description TEXT,

  -- AI generation metadata
  generated_by_ai BOOLEAN DEFAULT TRUE,
  readiness_score INTEGER,            -- 0-100
  based_on_vo2_max DECIMAL(4,1),
  based_on_aisri INTEGER,
  based_on_training_load DECIMAL(4,2),

  -- Scheduling
  scheduled_date DATE NOT NULL,
  garmin_synced BOOLEAN DEFAULT FALSE,
  garmin_workout_id BIGINT,

  -- Completion tracking
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  actual_duration_minutes INTEGER,
  actual_aisri_score INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(athlete_id, scheduled_date)
);

CREATE INDEX idx_scheduled_workouts_athlete_date
  ON scheduled_workouts(athlete_id, scheduled_date DESC);
CREATE INDEX idx_scheduled_workouts_pending
  ON scheduled_workouts(scheduled_date) WHERE NOT completed;
```

---

## 🔄 Integration with Progression Plan

### Link AI Workouts to 3:30/km Timeline

```dart
// lib/services/workout_progression_integrator.dart
class WorkoutProgressionIntegrator {

  static Future<WorkoutProtocol> generateWorkoutForProgressionWeek({
    required String athleteId,
    required int weekNumber,
  }) async {
    // 1. Get progression plan
    final plan = await ProgressionPlanService.getActivePlan(athleteId);
    if (plan == null) return _generateDefaultWorkout(athleteId);

    // 2. Get current week's plan
    final weekPlan = plan.weeklyPlans[weekNumber - 1];

    // 3. Check recovery status
    final recoveryOK = await _checkRecoveryStatus(athleteId);

    // 4. Generate workout aligned with progression
    if (!recoveryOK) {
      return _generateRecoveryOverride(athleteId, weekPlan);
    }

    return _generateProgressionWorkout(
      athleteId: athleteId,
      weekPlan: weekPlan,
      targetPace: plan.weeklyPlans[weekNumber - 1].targetPace,
    );
  }

  static WorkoutProtocol _generateProgressionWorkout({
    required String athleteId,
    required WeeklyPlan weekPlan,
    required double targetPace,
  }) {
    // Example: Week 10 of progression to 3:30/km
    // Current target pace: 7:00/km
    // This week's focus: Zone TH work

    return WorkoutProtocol(
      name: 'Progression Week ${weekPlan.weekNumber}',
      type: WorkoutType.run,
      targetZone: weekPlan.primaryZone,
      duration: Duration(minutes: weekPlan.totalMinutes),
      steps: _buildStepsForProgression(weekPlan, targetPace),
      description: 'Week ${weekPlan.weekNumber} of your journey to 3:30/km. '
          'Target pace this week: ${_formatPace(targetPace)}. '
          'Building ${weekPlan.primaryFocus} capacity.',
    );
  }
}
```

---

## 📲 User Notifications

### Push Notification Examples

**Evening (8 PM) - Workout Ready**:

```
🎯 Tomorrow's Workout Ready!

Threshold Intervals - 65 min
Zone TH: 6x6min @ Lactate Threshold

Your readiness: 82/100 - Great! 💪
Perfect day for quality work.

Tap to view details
```

**Morning (6 AM) - Workout Reminder**:

```
☀️ Good Morning! Ready for today's workout?

Easy Recovery Run - 30 min
Zone EN: Keep it easy today

Your body needs rest:
• Sleep: 5h 15m (needs improvement)
• Body Battery: 54
• Training Load: High

Tap to start on your watch
```

**After Completion**:

```
🎉 Workout Complete!

Threshold Intervals ✓
Duration: 67 min
AISRI Score: 76 (+3 from last week)
Form: Excellent

Great job maintaining cadence and GCT!
Tomorrow: Easy recovery run
```

---

## 🚀 Implementation Checklist

### Phase 1: AI Workout Generation (1 week)

- [ ] Build AI decision engine
- [ ] Implement readiness calculation
- [ ] Create workout templates for each intensity
- [ ] Add biomechanics cues based on AISRI
- [ ] Test with various athlete profiles

### Phase 2: Garmin Push Integration (1 week)

- [ ] Study Garmin Workout API documentation
- [ ] Implement workout format converter
- [ ] Build upload + schedule functions
- [ ] Handle OAuth authentication
- [ ] Test on real Garmin devices

### Phase 3: Automation (1 week)

- [ ] Set up daily background task
- [ ] Implement error handling + retries
- [ ] Add workout completion tracking
- [ ] Build notification system
- [ ] Create database schema

### Phase 4: Integration with Progression Plan (1 week)

- [ ] Link AI generator to 3:30/km timeline
- [ ] Ensure workouts align with current phase
- [ ] Adjust based on progress vs plan
- [ ] Add adaptive modifications

### Phase 5: Testing & Launch (1 week)

- [ ] Beta test with 10-15 athletes
- [ ] Verify workouts appear on watches
- [ ] Validate AI decisions make sense
- [ ] Gather feedback
- [ ] Full launch

---

## 📈 Success Metrics

**Track These After Launch**:

- Workout sync success rate (target: >95%)
- Workout completion rate (target: >70%)
- Athlete satisfaction with AI recommendations
- Injury rate compared to manual planning
- Progress toward 3:30/km goal

---

## 🎯 Summary

**Complete Flow**:

1. **8 PM Daily**: AI analyzes athlete data (VO2, sleep, recovery, AISRI)
2. **AI Generates**: Optimal workout for tomorrow based on readiness
3. **Pushes to Garmin**: Workout appears on athlete's Garmin Connect calendar
4. **Athlete Wakes Up**: Sees "Today's Workout" on watch
5. **Starts Workout**: Garmin guides through each step with HR/cadence targets
6. **After Completion**: SafeStride syncs results, updates AISRI, adjusts plan

**Result**: Fully automated, personalized training that adapts to athlete's recovery status and progression toward 3:30/km goal! 🚀

---

**Ready to implement? Start with Phase 1 (AI Generation) and test locally before Garmin integration!** ✅
