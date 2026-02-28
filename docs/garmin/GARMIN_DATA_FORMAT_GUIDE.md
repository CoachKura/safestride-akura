# Garmin Data Format & Integration Guide 📊

## Overview

This guide provides the complete data format specifications for integrating Garmin metrics into SafeStride, including API response formats, database schema, validation rules, and transformation logic.

---

## 🔌 Garmin API Endpoints & Response Formats

### 1. VO2 Max Data

**Endpoint**: `GET /wellness-api/rest/user/v2/vo2Max`

**Garmin API Response**:

```json
{
  "vo2MaxValues": [
    {
      "calendarDate": "2026-02-25",
      "vo2Max": 52.5,
      "genericActivityId": "RUNNING",
      "fitnessAge": 28,
      "timestamp": "2026-02-25T14:30:00.000Z"
    },
    {
      "calendarDate": "2026-02-20",
      "vo2Max": 51.8,
      "genericActivityId": "RUNNING",
      "timestamp": "2026-02-20T09:15:00.000Z"
    }
  ]
}
```

**SafeStride Storage Format**:

```dart
// Database: athlete_metrics table
{
  "athlete_id": "uuid-here",
  "vo2_max": 52.5,                           // DECIMAL(4,1) - ml/kg/min
  "vo2_max_timestamp": "2026-02-25T14:30:00Z", // TIMESTAMPTZ
  "fitness_age": 28,                         // INTEGER (optional)
  "vo2_max_sport_type": "running",          // TEXT
  "updated_at": "2026-02-25T14:30:00Z"
}
```

**Validation Rules**:

- Range: 20.0 - 85.0 ml/kg/min
- Precision: 1 decimal place
- Update frequency: Store only if newer timestamp
- Sport type filter: Only accept "RUNNING" activities

---

### 2. Ground Contact Time (GCT) & Running Dynamics

**Endpoint**: `GET /wellness-api/rest/runningDynamics/{activityId}`

**Garmin API Response**:

```json
{
  "activityId": 12345678901,
  "startTimeGMT": "2026-02-25T06:00:00.000Z",
  "runningDynamics": {
    "groundContactTime": 245, // milliseconds
    "groundContactBalance": 50.2, // % (left side)
    "verticalOscillation": 8.5, // centimeters
    "verticalRatio": 7.8, // % (VO / stride length)
    "strideLength": 1.24, // meters
    "cadence": 178, // steps per minute (SPM)
    "avgPower": 285 // watts
  },
  "averageValues": {
    "avgGroundContactTime": 248,
    "avgGroundContactBalance": 50.1,
    "avgVerticalOscillation": 8.7,
    "avgStrideLength": 1.22,
    "avgCadence": 176
  }
}
```

**SafeStride Storage Format**:

```dart
// Database: athlete_metrics table
{
  "athlete_id": "uuid-here",
  "gct": 248,                               // INTEGER - milliseconds
  "gct_balance": 50.1,                      // DECIMAL(5,2) - % left
  "vertical_oscillation": 8.7,              // DECIMAL(5,2) - cm
  "vertical_ratio": 7.8,                    // DECIMAL(5,2) - %
  "stride_length": 1.22,                    // DECIMAL(5,2) - meters
  "avg_cadence": 176,                       // INTEGER - SPM
  "avg_power": 285,                         // INTEGER - watts (optional)
  "running_dynamics_updated_at": "2026-02-25T06:00:00Z"
}
```

**Validation Rules**:

- GCT: 150-350ms (typical range)
- GCT Balance: 48.0-52.0% (ideal: 50%)
- Vertical Oscillation: 5.0-15.0cm
- Stride Length: 0.80-2.00m
- Cadence: 140-220 SPM
- Update: Use `averageValues` from most recent activity

---

### 3. Heart Rate Variability (HRV)

**Endpoint**: `GET /wellness-api/rest/hrv/{{date}}`

**Garmin API Response**:

```json
{
  "calendarDate": "2026-02-25",
  "weeklyAvg": 42, // milliseconds
  "lastNightAvg": 45, // milliseconds
  "lastNight5MinHigh": 68, // milliseconds
  "baseline": {
    "lowUpper": 32,
    "balancedLow": 33,
    "balancedUpper": 52,
    "markerValue": 42
  },
  "status": "BALANCED", // BALANCED, UNBALANCED, LOW, etc.
  "feedbackPhrase": "Your HRV is balanced",
  "createTimeStamp": "2026-02-25T08:30:00.000Z"
}
```

**SafeStride Storage Format**:

```dart
// Database: garmin_wellness_data table
{
  "athlete_id": "uuid-here",
  "date": "2026-02-25",
  "hrv_morning": 45,                        // INTEGER - ms (lastNightAvg)
  "hrv_weekly_avg": 42,                     // INTEGER - ms
  "hrv_status": "balanced",                 // TEXT (lowercase)
  "hrv_baseline_low": 32,
  "hrv_baseline_high": 52,
  "updated_at": "2026-02-25T08:30:00Z"
}
```

**Validation Rules**:

- Range: 10-150ms (typical range)
- Status values: "balanced", "unbalanced", "low", "high"
- Update frequency: Once per day (morning reading)
- Use `lastNightAvg` as primary value

---

### 4. Sleep Data

**Endpoint**: `GET /wellness-api/rest/dailySleep/{{date}}`

**Garmin API Response**:

```json
{
  "dailySleepDTO": {
    "calendarDate": "2026-02-25",
    "sleepTimeSeconds": 28800, // 8 hours
    "napTimeSeconds": 0,
    "sleepWindowConfirmed": true,
    "sleepWindowConfirmationType": "AUTO_CONFIRMED",
    "sleepStartTimestampGMT": 1709078400000,
    "sleepEndTimestampGMT": 1709107200000,
    "sleepQualityTypePK": null,
    "sleepResultTypePK": null,
    "deepSleepSeconds": 7200, // 2 hours
    "lightSleepSeconds": 16200, // 4.5 hours
    "remSleepSeconds": 5400, // 1.5 hours
    "awakeSleepSeconds": 0,
    "unmeasurableSleepSeconds": 0,
    "avgSleepStress": 18, // 0-100
    "sleepScores": {
      "totalDuration": {
        "qualifierKey": "GOOD",
        "value": 85
      },
      "stress": {
        "qualifierKey": "GOOD",
        "value": 82
      },
      "awakeCount": {
        "qualifierKey": "EXCELLENT",
        "value": 95
      },
      "overall": {
        "qualifierKey": "GOOD",
        "value": 83
      },
      "remPercentage": {
        "qualifierKey": "FAIR",
        "value": 70
      },
      "restlessness": {
        "qualifierKey": "GOOD",
        "value": 78
      },
      "lightPercentage": {
        "qualifierKey": "GOOD",
        "value": 80
      },
      "deepPercentage": {
        "qualifierKey": "GOOD",
        "value": 75
      }
    }
  }
}
```

**SafeStride Storage Format**:

```dart
// Database: garmin_wellness_data table
{
  "athlete_id": "uuid-here",
  "date": "2026-02-25",
  "sleep_score": 83,                        // INTEGER (0-100)
  "sleep_duration_minutes": 480,            // INTEGER (28800/60)
  "deep_sleep_minutes": 120,                // INTEGER (7200/60)
  "light_sleep_minutes": 270,               // INTEGER (16200/60)
  "rem_sleep_minutes": 90,                  // INTEGER (5400/60)
  "awake_minutes": 0,                       // INTEGER
  "sleep_start": "2026-02-24T22:00:00Z",   // TIMESTAMPTZ
  "sleep_end": "2026-02-25T06:00:00Z",     // TIMESTAMPTZ
  "sleep_quality": "good",                  // TEXT (from overall.qualifierKey)
  "updated_at": "2026-02-25T08:00:00Z"
}
```

**Validation Rules**:

- Total sleep: 180-720 minutes (3-12 hours)
- Deep sleep: 10-30% of total
- REM sleep: 15-25% of total
- Light sleep: 45-55% of total
- Sleep score: 0-100 (Good: 70+, Fair: 60-69, Poor: <60)

---

### 5. Wellness Metrics (Stress, Body Battery, Resting HR)

**Endpoint**: `GET /wellness-api/rest/wellness/{{date}}`

**Garmin API Response**:

```json
{
  "calendarDate": "2026-02-25",
  "restingHeartRate": 52, // BPM
  "bodyBatteryMostRecentValue": 75, // 0-100
  "bodyBatteryChargedValue": 95, // Morning value
  "bodyBatteryDrainedValue": 45, // Evening value
  "averageStressLevel": 28, // 0-100
  "maxStressLevel": 65,
  "stressDuration": 14400, // seconds in stress
  "restDuration": 72000, // seconds at rest
  "activityDuration": 3600, // seconds active
  "lowStressDuration": 50400,
  "mediumStressDuration": 7200,
  "highStressDuration": 7200,
  "steps": 12500,
  "distanceInMeters": 8500,
  "activeKilocalories": 650,
  "kilocalories": 2300,
  "floorsAscended": 8,
  "floorsDescended": 6,
  "intensityMinutesGoal": 150,
  "vigorousIntensityMinutes": 45,
  "moderateIntensityMinutes": 90
}
```

**SafeStride Storage Format**:

```dart
// Database: garmin_wellness_data table
{
  "athlete_id": "uuid-here",
  "date": "2026-02-25",

  // Heart rate
  "resting_hr": 52,                         // INTEGER - BPM

  // Body Battery
  "body_battery": 75,                       // INTEGER (current)
  "body_battery_charged": 95,               // INTEGER (morning peak)
  "body_battery_drained": 45,               // INTEGER (evening low)

  // Stress
  "stress_level": 28,                       // INTEGER (average)
  "max_stress_level": 65,                   // INTEGER
  "stress_duration_minutes": 240,           // INTEGER (14400/60)
  "rest_duration_minutes": 1200,            // INTEGER (72000/60)

  // Activity
  "steps": 12500,                           // INTEGER
  "distance_meters": 8500,                  // INTEGER
  "active_calories": 650,                   // INTEGER
  "total_calories": 2300,                   // INTEGER
  "vigorous_minutes": 45,                   // INTEGER
  "moderate_minutes": 90,                   // INTEGER

  "updated_at": "2026-02-25T23:59:59Z"
}
```

**Validation Rules**:

- Resting HR: 30-100 BPM
- Body Battery: 0-100 (Good: 75+, Fair: 50-74, Low: <50)
- Stress: 0-100 (Low: 0-25, Medium: 26-50, High: 51-75, Very High: 76-100)
- Steps: 0-50,000 per day
- Active calories: 0-5,000 per day

---

## 🗄️ Complete Database Schema

### athlete_metrics table (Advanced Metrics)

```sql
CREATE TABLE IF NOT EXISTS athlete_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES auth.users(id) NOT NULL,

  -- VO2 Max
  vo2_max DECIMAL(4,1),                     -- ml/kg/min (20.0-85.0)
  vo2_max_timestamp TIMESTAMPTZ,
  fitness_age INTEGER,
  vo2_max_sport_type TEXT DEFAULT 'running',

  -- Running Dynamics
  gct INTEGER,                              -- Ground Contact Time (ms)
  gct_balance DECIMAL(5,2),                 -- % left (48-52 ideal)
  vertical_oscillation DECIMAL(5,2),        -- cm
  vertical_ratio DECIMAL(5,2),              -- %
  stride_length DECIMAL(5,2),               -- meters
  avg_cadence INTEGER,                      -- SPM
  avg_power INTEGER,                        -- watts
  running_dynamics_updated_at TIMESTAMPTZ,

  -- Thresholds
  lactate_threshold_hr INTEGER,            -- BPM
  lactate_threshold_pace DECIMAL(5,2),     -- min/km
  functional_threshold_power INTEGER,       -- watts (for cycling)

  -- Training Status
  training_load INTEGER,                    -- 0-300
  training_effect DECIMAL(3,1),             -- 0.0-5.0
  training_status TEXT,                     -- productive, maintaining, detraining, etc.
  recovery_time INTEGER,                    -- hours

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(athlete_id)
);

-- Index for quick athlete lookups
CREATE INDEX idx_athlete_metrics_athlete_id ON athlete_metrics(athlete_id);
```

### garmin_wellness_data table (Daily Wellness)

```sql
CREATE TABLE IF NOT EXISTS garmin_wellness_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES auth.users(id) NOT NULL,
  date DATE NOT NULL,

  -- Heart Metrics
  resting_hr INTEGER,                       -- BPM
  hrv_morning INTEGER,                      -- ms
  hrv_weekly_avg INTEGER,                   -- ms
  hrv_status TEXT,                          -- balanced, unbalanced, low, high
  hrv_baseline_low INTEGER,
  hrv_baseline_high INTEGER,

  -- Sleep
  sleep_score INTEGER,                      -- 0-100
  sleep_duration_minutes INTEGER,
  deep_sleep_minutes INTEGER,
  light_sleep_minutes INTEGER,
  rem_sleep_minutes INTEGER,
  awake_minutes INTEGER,
  sleep_start TIMESTAMPTZ,
  sleep_end TIMESTAMPTZ,
  sleep_quality TEXT,                       -- excellent, good, fair, poor

  -- Body Battery
  body_battery INTEGER,                     -- 0-100 (current)
  body_battery_charged INTEGER,             -- Morning peak
  body_battery_drained INTEGER,             -- Evening low

  -- Stress
  stress_level INTEGER,                     -- 0-100 (average)
  max_stress_level INTEGER,
  stress_duration_minutes INTEGER,
  rest_duration_minutes INTEGER,

  -- Activity
  steps INTEGER,
  distance_meters INTEGER,
  active_calories INTEGER,
  total_calories INTEGER,
  vigorous_minutes INTEGER,
  moderate_minutes INTEGER,
  floors_ascended INTEGER,
  floors_descended INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(athlete_id, date)
);

-- Indexes
CREATE INDEX idx_wellness_athlete_date ON garmin_wellness_data(athlete_id, date DESC);
CREATE INDEX idx_wellness_date ON garmin_wellness_data(date DESC);
```

---

## 🔄 Data Transformation & Mapping

### Complete Dart Service Implementation

```dart
// lib/services/garmin_data_transformer.dart
import 'package:intl/intl.dart';

class GarminDataTransformer {

  // ================================
  // VO2 MAX TRANSFORMATION
  // ================================

  static Map<String, dynamic>? transformVO2Max(Map<String, dynamic> garminResponse) {
    try {
      final vo2MaxValues = garminResponse['vo2MaxValues'] as List?;
      if (vo2MaxValues == null || vo2MaxValues.isEmpty) return null;

      // Get most recent running VO2 max
      final runningVO2 = vo2MaxValues.firstWhere(
        (v) => v['genericActivityId'] == 'RUNNING',
        orElse: () => null,
      );

      if (runningVO2 == null) return null;

      final vo2Max = (runningVO2['vo2Max'] as num).toDouble();

      // Validation
      if (vo2Max < 20.0 || vo2Max > 85.0) {
        print('Warning: VO2 Max out of valid range: $vo2Max');
        return null;
      }

      return {
        'vo2_max': double.parse(vo2Max.toStringAsFixed(1)),
        'vo2_max_timestamp': runningVO2['timestamp'],
        'fitness_age': runningVO2['fitnessAge'],
        'vo2_max_sport_type': 'running',
        'updated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error transforming VO2 Max: $e');
      return null;
    }
  }

  // ================================
  // RUNNING DYNAMICS TRANSFORMATION
  // ================================

  static Map<String, dynamic>? transformRunningDynamics(Map<String, dynamic> garminResponse) {
    try {
      final avgValues = garminResponse['averageValues'] as Map<String, dynamic>?;
      if (avgValues == null) return null;

      final gct = avgValues['avgGroundContactTime'] as int?;
      final gctBalance = avgValues['avgGroundContactBalance'] as num?;
      final vertOsc = avgValues['avgVerticalOscillation'] as num?;
      final strideLength = avgValues['avgStrideLength'] as num?;
      final cadence = avgValues['avgCadence'] as int?;

      // Validation
      if (gct != null && (gct < 150 || gct > 350)) {
        print('Warning: GCT out of valid range: $gct ms');
      }

      if (gctBalance != null && (gctBalance < 48.0 || gctBalance > 52.0)) {
        print('Info: GCT Balance shows asymmetry: $gctBalance%');
      }

      return {
        'gct': gct,
        'gct_balance': gctBalance?.toStringAsFixed(2),
        'vertical_oscillation': vertOsc?.toStringAsFixed(2),
        'vertical_ratio': garminResponse['runningDynamics']?['verticalRatio']?.toStringAsFixed(2),
        'stride_length': strideLength?.toStringAsFixed(2),
        'avg_cadence': cadence,
        'avg_power': avgValues['avgPower'],
        'running_dynamics_updated_at': garminResponse['startTimeGMT'],
      };
    } catch (e) {
      print('Error transforming Running Dynamics: $e');
      return null;
    }
  }

  // ================================
  // HRV TRANSFORMATION
  // ================================

  static Map<String, dynamic>? transformHRV(Map<String, dynamic> garminResponse) {
    try {
      final lastNightAvg = garminResponse['lastNightAvg'] as int?;
      final weeklyAvg = garminResponse['weeklyAvg'] as int?;
      final status = garminResponse['status'] as String?;
      final baseline = garminResponse['baseline'] as Map<String, dynamic>?;

      if (lastNightAvg == null) return null;

      // Validation
      if (lastNightAvg < 10 || lastNightAvg > 150) {
        print('Warning: HRV out of typical range: $lastNightAvg ms');
      }

      return {
        'hrv_morning': lastNightAvg,
        'hrv_weekly_avg': weeklyAvg,
        'hrv_status': status?.toLowerCase(),
        'hrv_baseline_low': baseline?['balancedLow'],
        'hrv_baseline_high': baseline?['balancedUpper'],
      };
    } catch (e) {
      print('Error transforming HRV: $e');
      return null;
    }
  }

  // ================================
  // SLEEP TRANSFORMATION
  // ================================

  static Map<String, dynamic>? transformSleep(Map<String, dynamic> garminResponse) {
    try {
      final sleepDTO = garminResponse['dailySleepDTO'] as Map<String, dynamic>?;
      if (sleepDTO == null) return null;

      final totalSeconds = sleepDTO['sleepTimeSeconds'] as int?;
      final deepSeconds = sleepDTO['deepSleepSeconds'] as int?;
      final lightSeconds = sleepDTO['lightSleepSeconds'] as int?;
      final remSeconds = sleepDTO['remSleepSeconds'] as int?;
      final awakeSeconds = sleepDTO['awakeSleepSeconds'] as int? ?? 0;

      if (totalSeconds == null) return null;

      final totalMinutes = (totalSeconds / 60).round();

      // Validation
      if (totalMinutes < 180 || totalMinutes > 720) {
        print('Warning: Sleep duration unusual: $totalMinutes minutes');
      }

      // Convert timestamps
      final startMs = sleepDTO['sleepStartTimestampGMT'] as int?;
      final endMs = sleepDTO['sleepEndTimestampGMT'] as int?;

      DateTime? sleepStart;
      DateTime? sleepEnd;

      if (startMs != null) {
        sleepStart = DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
      }
      if (endMs != null) {
        sleepEnd = DateTime.fromMillisecondsSinceEpoch(endMs, isUtc: true);
      }

      // Extract sleep score
      final scores = sleepDTO['sleepScores'] as Map<String, dynamic>?;
      final overallScore = scores?['overall']?['value'] as int?;
      final qualityKey = scores?['overall']?['qualifierKey'] as String?;

      return {
        'sleep_score': overallScore,
        'sleep_duration_minutes': totalMinutes,
        'deep_sleep_minutes': deepSeconds != null ? (deepSeconds / 60).round() : null,
        'light_sleep_minutes': lightSeconds != null ? (lightSeconds / 60).round() : null,
        'rem_sleep_minutes': remSeconds != null ? (remSeconds / 60).round() : null,
        'awake_minutes': (awakeSeconds / 60).round(),
        'sleep_start': sleepStart?.toIso8601String(),
        'sleep_end': sleepEnd?.toIso8601String(),
        'sleep_quality': qualityKey?.toLowerCase(),
      };
    } catch (e) {
      print('Error transforming Sleep: $e');
      return null;
    }
  }

  // ================================
  // WELLNESS TRANSFORMATION
  // ================================

  static Map<String, dynamic>? transformWellness(Map<String, dynamic> garminResponse) {
    try {
      return {
        // Heart rate
        'resting_hr': garminResponse['restingHeartRate'],

        // Body Battery
        'body_battery': garminResponse['bodyBatteryMostRecentValue'],
        'body_battery_charged': garminResponse['bodyBatteryChargedValue'],
        'body_battery_drained': garminResponse['bodyBatteryDrainedValue'],

        // Stress
        'stress_level': garminResponse['averageStressLevel'],
        'max_stress_level': garminResponse['maxStressLevel'],
        'stress_duration_minutes': _secondsToMinutes(garminResponse['stressDuration']),
        'rest_duration_minutes': _secondsToMinutes(garminResponse['restDuration']),

        // Activity
        'steps': garminResponse['steps'],
        'distance_meters': garminResponse['distanceInMeters'],
        'active_calories': garminResponse['activeKilocalories'],
        'total_calories': garminResponse['kilocalories'],
        'vigorous_minutes': garminResponse['vigorousIntensityMinutes'],
        'moderate_minutes': garminResponse['moderateIntensityMinutes'],
        'floors_ascended': garminResponse['floorsAscended'],
        'floors_descended': garminResponse['floorsDescended'],
      };
    } catch (e) {
      print('Error transforming Wellness: $e');
      return null;
    }
  }

  // Helper
  static int? _secondsToMinutes(int? seconds) {
    return seconds != null ? (seconds / 60).round() : null;
  }

  // ================================
  // COMBINED DAILY SYNC
  // ================================

  static Future<void> syncDailyGarminData({
    required String athleteId,
    required String accessToken,
    required String accessSecret,
    required DateTime date,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    try {
      // Fetch all data for the date
      final hrvData = await _fetchGarminHRV(accessToken, accessSecret, dateStr);
      final sleepData = await _fetchGarminSleep(accessToken, accessSecret, dateStr);
      final wellnessData = await _fetchGarminWellness(accessToken, accessSecret, dateStr);

      // Transform data
      final transformedData = {
        'athlete_id': athleteId,
        'date': dateStr,
        ...?transformHRV(hrvData),
        ...?transformSleep(sleepData),
        ...?transformWellness(wellnessData),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Save to database (UPSERT)
      await Supabase.instance.client
          .from('garmin_wellness_data')
          .upsert(transformedData);

      print('✅ Synced Garmin wellness data for $dateStr');

    } catch (e) {
      print('❌ Error syncing Garmin data: $e');
      rethrow;
    }
  }
}
```

---

## 📥 Complete Sync Service Example

```dart
// lib/services/garmin_sync_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oauth1/oauth1.dart' as oauth1;
import 'package:supabase_flutter/supabase_flutter.dart';

class GarminSyncService {
  static const String baseUrl = 'https://apis.garmin.com';

  static Future<void> syncAllGarminMetrics(String athleteId) async {
    try {
      // Get credentials
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('garmin_access_token, garmin_access_secret')
          .eq('id', athleteId)
          .single();

      if (profile['garmin_access_token'] == null) {
        throw Exception('Garmin not connected');
      }

      final accessToken = profile['garmin_access_token'];
      final accessSecret = profile['garmin_access_secret'];

      // Sync last 7 days of wellness data
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        await GarminDataTransformer.syncDailyGarminData(
          athleteId: athleteId,
          accessToken: accessToken,
          accessSecret: accessSecret,
          date: date,
        );
      }

      // Sync VO2 Max (latest value)
      await _syncVO2Max(athleteId, accessToken, accessSecret);

      // Sync latest running dynamics
      await _syncLatestRunningDynamics(athleteId, accessToken, accessSecret);

      // Update last sync timestamp
      await Supabase.instance.client.from('profiles').update({
        'garmin_last_sync': DateTime.now().toIso8601String(),
      }).eq('id', athleteId);

      print('✅ Complete Garmin sync finished for athlete: $athleteId');

    } catch (e) {
      print('❌ Garmin sync error: $e');
      rethrow;
    }
  }

  static Future<void> _syncVO2Max(
    String athleteId,
    String accessToken,
    String accessSecret,
  ) async {
    final response = await _makeGarminRequest(
      '/wellness-api/rest/user/v2/vo2Max',
      accessToken,
      accessSecret,
    );

    final transformed = GarminDataTransformer.transformVO2Max(response);
    if (transformed != null) {
      await Supabase.instance.client
          .from('athlete_metrics')
          .upsert({
            'athlete_id': athleteId,
            ...transformed,
          });
    }
  }

  static Future<Map<String, dynamic>> _makeGarminRequest(
    String endpoint,
    String accessToken,
    String accessSecret,
  ) async {
    // OAuth 1.0a signing
    final platform = oauth1.Platform(
      'https://apis.garmin.com/oauth-service/oauth/request_token',
      'https://connect.garmin.com/oauthConfirm',
      'https://apis.garmin.com/oauth-service/oauth/access_token',
      oauth1.SignatureMethods.hmacSha1,
    );

    final clientCredentials = oauth1.ClientCredentials(
      'YOUR_GARMIN_CONSUMER_KEY',
      'YOUR_GARMIN_CONSUMER_SECRET',
    );

    final credentials = oauth1.Credentials(accessToken, accessSecret);

    final client = oauth1.Client(
      platform.signatureMethod,
      clientCredentials,
      credentials,
    );

    final response = await client.get(Uri.parse('$baseUrl$endpoint'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Garmin API error: ${response.statusCode}');
    }
  }
}
```

---

## ✅ Validation & Error Handling

```dart
// lib/services/garmin_data_validator.dart
class GarminDataValidator {
  static bool validateVO2Max(double? vo2Max) {
    if (vo2Max == null) return false;
    return vo2Max >= 20.0 && vo2Max <= 85.0;
  }

  static bool validateGCT(int? gct) {
    if (gct == null) return false;
    return gct >= 150 && gct <= 350;
  }

  static bool validateCadence(int? cadence) {
    if (cadence == null) return false;
    return cadence >= 140 && cadence <= 220;
  }

  static bool validateHRV(int? hrv) {
    if (hrv == null) return false;
    return hrv >= 10 && hrv <= 150;
  }

  static bool validateSleepDuration(int? minutes) {
    if (minutes == null) return false;
    return minutes >= 180 && minutes <= 720; // 3-12 hours
  }

  static bool validateRestingHR(int? bpm) {
    if (bpm == null) return false;
    return bpm >= 30 && bpm <= 100;
  }

  static bool validateBodyBattery(int? value) {
    if (value == null) return false;
    return value >= 0 && value <= 100;
  }
}
```

---

## 🧪 Testing Data Transformation

```dart
// test/services/garmin_data_transformer_test.dart
void main() {
  group('Garmin Data Transformation Tests', () {

    test('Transform VO2 Max correctly', () {
      final mockResponse = {
        'vo2MaxValues': [
          {
            'calendarDate': '2026-02-25',
            'vo2Max': 52.5,
            'genericActivityId': 'RUNNING',
            'fitnessAge': 28,
            'timestamp': '2026-02-25T14:30:00.000Z',
          }
        ]
      };

      final result = GarminDataTransformer.transformVO2Max(mockResponse);

      expect(result, isNotNull);
      expect(result!['vo2_max'], 52.5);
      expect(result['fitness_age'], 28);
      expect(result['vo2_max_sport_type'], 'running');
    });

    test('Transform Running Dynamics correctly', () {
      final mockResponse = {
        'averageValues': {
          'avgGroundContactTime': 248,
          'avgGroundContactBalance': 50.1,
          'avgVerticalOscillation': 8.7,
          'avgStrideLength': 1.22,
          'avgCadence': 176,
        },
        'runningDynamics': {
          'verticalRatio': 7.8,
        },
        'startTimeGMT': '2026-02-25T06:00:00.000Z',
      };

      final result = GarminDataTransformer.transformRunningDynamics(mockResponse);

      expect(result, isNotNull);
      expect(result!['gct'], 248);
      expect(result['gct_balance'], '50.10');
      expect(result['avg_cadence'], 176);
    });

    test('Validate HRV range', () {
      expect(GarminDataValidator.validateHRV(45), true);
      expect(GarminDataValidator.validateHRV(5), false);
      expect(GarminDataValidator.validateHRV(200), false);
    });
  });
}
```

---

## 📊 Summary Table

| Metric             | Garmin Format     | SafeStride Format | Validation Range | Update Frequency            |
| ------------------ | ----------------- | ----------------- | ---------------- | --------------------------- |
| **VO2 Max**        | Float (ml/kg/min) | DECIMAL(4,1)      | 20.0-85.0        | After qualifying activities |
| **GCT**            | Integer (ms)      | INTEGER           | 150-350          | After each run              |
| **GCT Balance**    | Float (%)         | DECIMAL(5,2)      | 48.0-52.0        | After each run              |
| **Cadence**        | Integer (SPM)     | INTEGER           | 140-220          | After each run              |
| **HRV**            | Integer (ms)      | INTEGER           | 10-150           | Daily (morning)             |
| **Sleep Duration** | Integer (seconds) | INTEGER (minutes) | 180-720          | Daily                       |
| **Sleep Score**    | Integer           | INTEGER           | 0-100            | Daily                       |
| **Resting HR**     | Integer (BPM)     | INTEGER           | 30-100           | Daily                       |
| **Body Battery**   | Integer           | INTEGER           | 0-100            | Real-time                   |
| **Stress Level**   | Integer           | INTEGER           | 0-100            | Real-time                   |

---

## 🎯 Real-World Example: Transforming Actual Garmin Activity Data

### Sample Activity: Chennai Zone EN & TH Run

Here's how to process a real Garmin activity with complete metrics:

**Raw Garmin Activity Data** (from Garmin Connect API):

```json
{
  "activityId": 12345678901,
  "activityName": "Chennai - Zone EN & TH Run",
  "activityType": "running",
  "startTimeGMT": "2026-02-26T00:57:00.000Z",
  "distance": 8480.0,
  "duration": 4654.0,
  "elapsedDuration": 4676.0,
  "movingDuration": 4483.0,
  "averageSpeed": 1.822,
  "maxSpeed": 2.789,
  "calories": 628,
  "averageHR": 140,
  "maxHR": 164,
  "totalAscent": 18,
  "totalDescent": 23,
  "minElevation": 17,
  "maxElevation": 24,
  "avgPower": 205,
  "maxPower": 336,
  "avgRunCadence": 146,
  "maxRunCadence": 180,
  "avgStrideLength": 0.73,
  "avgVerticalOscillation": 7.3,
  "avgGroundContactTime": 290,
  "avgVerticalRatio": 10.1,
  "aerobicTrainingEffect": 3.6,
  "anaerobicTrainingEffect": 0.5,
  "exerciseLoad": 99,
  "avgTemperature": 28.8,
  "maxTemperature": 31.0,
  "minTemperature": 27.0,
  "intensityMinutesVigorous": 19,
  "intensityMinutesModerate": 14,
  "performanceCondition": 1,
  "executionScore": 77,
  "staminaBeginning": 100,
  "staminaEnding": 45,
  "staminaMin": 45,
  "bodyBatteryNet": -20,
  "hrTimeInZone1": 711,
  "hrTimeInZone2": 1639,
  "hrTimeInZone3": 1108,
  "hrTimeInZone4": 1166,
  "hrTimeInZone5": 0,
  "splits": [
    {
      "splitType": "WARM_UP",
      "distance": 2000,
      "duration": 1128,
      "averagePace": 9.4,
      "averageHR": 126,
      "avgCadence": 150,
      "avgGCT": 294
    },
    {
      "splitType": "RUN",
      "distance": 820,
      "duration": 360,
      "averagePace": 7.3,
      "averageHR": 151,
      "avgCadence": 159,
      "avgGCT": 277
    }
    // ... more splits
  ]
}
```

**Transformation to SafeStride Format**:

```dart
// lib/services/garmin_activity_processor.dart
class GarminActivityProcessor {

  static Future<void> processAndStoreActivity({
    required String athleteId,
    required Map<String, dynamic> garminActivity,
  }) async {

    // ============================================
    // 1. STORE ACTIVITY BASICS
    // ============================================
    final activityData = {
      'id': uuid.v4(),
      'athlete_id': athleteId,
      'garmin_activity_id': garminActivity['activityId'],
      'activity_name': garminActivity['activityName'],
      'activity_type': 'running',
      'start_time': garminActivity['startTimeGMT'],
      'distance_meters': garminActivity['distance'], // 8480 m
      'duration_seconds': garminActivity['duration'], // 4654 s
      'moving_time_seconds': garminActivity['movingDuration'], // 4483 s
      'average_pace': _metersPerSecondToPaceMinPerKm(
        garminActivity['averageSpeed']
      ), // 9.15 min/km
      'average_hr': garminActivity['averageHR'], // 140 bpm
      'max_hr': garminActivity['maxHR'], // 164 bpm
      'calories': garminActivity['calories'], // 628
      'elevation_gain': garminActivity['totalAscent'], // 18 m
      'created_at': DateTime.now().toIso8601String(),
    };

    await Supabase.instance.client
        .from('garmin_activities')
        .insert(activityData);

    // ============================================
    // 2. UPDATE RUNNING DYNAMICS (athlete_metrics)
    // ============================================
    final runningDynamics = {
      'athlete_id': athleteId,
      'avg_cadence': garminActivity['avgRunCadence'], // 146 spm
      'stride_length': garminActivity['avgStrideLength'], // 0.73 m
      'vertical_oscillation': garminActivity['avgVerticalOscillation'], // 7.3 cm
      'gct': garminActivity['avgGroundContactTime'], // 290 ms
      'vertical_ratio': garminActivity['avgVerticalRatio'], // 10.1%
      'avg_power': garminActivity['avgPower'], // 205 W
      'running_dynamics_updated_at': garminActivity['startTimeGMT'],
    };

    await Supabase.instance.client
        .from('athlete_metrics')
        .upsert(runningDynamics);

    // ============================================
    // 3. UPDATE TRAINING METRICS
    // ============================================
    final trainingMetrics = {
      'athlete_id': athleteId,
      'training_effect': garminActivity['aerobicTrainingEffect'], // 3.6
      'training_load': garminActivity['exerciseLoad'], // 99
      'training_status': _determineTrainingStatus(
        garminActivity['aerobicTrainingEffect']
      ), // 'productive'
    };

    await Supabase.instance.client
        .from('athlete_metrics')
        .upsert(trainingMetrics);

    // ============================================
    // 4. STORE WELLNESS IMPACT (daily summary)
    // ============================================
    final date = DateTime.parse(garminActivity['startTimeGMT'])
        .toIso8601String()
        .split('T')[0];

    final wellnessImpact = {
      'athlete_id': athleteId,
      'date': date,
      'vigorous_minutes': garminActivity['intensityMinutesVigorous'], // 19 min
      'moderate_minutes': garminActivity['intensityMinutesModerate'], // 14 min
      'body_battery': null, // Will be updated from wellness sync
      'updated_at': DateTime.now().toIso8601String(),
    };

    await Supabase.instance.client
        .from('garmin_wellness_data')
        .upsert(wellnessImpact);

    // ============================================
    // 5. CALCULATE AND UPDATE PROFILE METRICS
    // ============================================
    await _updateProfileFromActivity(athleteId, activityData);

    print('✅ Activity processed: ${garminActivity['activityName']}');
    print('   Distance: ${(garminActivity['distance'] / 1000).toStringAsFixed(2)} km');
    print('   Pace: ${activityData['average_pace']} min/km');
    print('   Cadence: ${garminActivity['avgRunCadence']} spm');
    print('   GCT: ${garminActivity['avgGroundContactTime']} ms');
  }

  // Helper: Convert m/s to min/km
  static double _metersPerSecondToPaceMinPerKm(double metersPerSecond) {
    if (metersPerSecond == 0) return 0;
    // 1 km = 1000m, pace in min/km
    final secondsPerKm = 1000 / metersPerSecond;
    return secondsPerKm / 60; // Convert to minutes
  }

  // Helper: Determine training status from aerobic TE
  static String _determineTrainingStatus(double aerobicTE) {
    if (aerobicTE >= 4.0) return 'highly_impacting';
    if (aerobicTE >= 3.0) return 'impacting';
    if (aerobicTE >= 2.0) return 'maintaining';
    if (aerobicTE >= 1.0) return 'recovery';
    return 'no_benefit';
  }

  // Update profile with rolling averages
  static Future<void> _updateProfileFromActivity(
    String athleteId,
    Map<String, dynamic> activityData,
  ) async {
    // Get last 4 weeks of activities
    final fourWeeksAgo = DateTime.now().subtract(Duration(days: 28));

    final recentActivities = await Supabase.instance.client
        .from('garmin_activities')
        .select('distance_meters, average_pace, average_hr')
        .eq('athlete_id', athleteId)
        .gte('start_time', fourWeeksAgo.toIso8601String())
        .order('start_time', ascending: false);

    // Calculate averages
    if (recentActivities.isNotEmpty) {
      final totalDistance = recentActivities.fold(
        0.0,
        (sum, a) => sum + (a['distance_meters'] as num).toDouble(),
      );
      final avgPace = recentActivities.fold(
        0.0,
        (sum, a) => sum + (a['average_pace'] as num).toDouble(),
      ) / recentActivities.length;

      final weeklyMileage = totalDistance / 1000 / 4; // km per week

      // Update profile
      await Supabase.instance.client.from('profiles').update({
        'strava_average_pace': avgPace,
        'weekly_mileage': weeklyMileage,
        'total_activities': recentActivities.length,
        'last_sync': DateTime.now().toIso8601String(),
      }).eq('id', athleteId);
    }
  }
}
```

**Resulting Database Records**:

### garmin_activities table:

```sql
INSERT INTO garmin_activities VALUES (
  'uuid-123',                           -- id
  'athlete-uuid',                       -- athlete_id
  12345678901,                          -- garmin_activity_id
  'Chennai - Zone EN & TH Run',        -- activity_name
  'running',                            -- activity_type
  '2026-02-26T00:57:00.000Z',          -- start_time
  8480,                                 -- distance_meters
  4654,                                 -- duration_seconds
  4483,                                 -- moving_time_seconds
  9.15,                                 -- average_pace (min/km)
  140,                                  -- average_hr
  164,                                  -- max_hr
  628,                                  -- calories
  18,                                   -- elevation_gain
  NOW()                                 -- created_at
);
```

### athlete_metrics table:

```sql
UPDATE athlete_metrics SET
  avg_cadence = 146,                    -- spm
  stride_length = 0.73,                 -- meters
  vertical_oscillation = 7.3,           -- cm
  gct = 290,                            -- ms
  vertical_ratio = 10.1,                -- %
  avg_power = 205,                      -- watts
  training_effect = 3.6,                -- aerobic TE
  training_load = 99,                   -- exercise load
  training_status = 'impacting',
  running_dynamics_updated_at = '2026-02-26T00:57:00.000Z',
  updated_at = NOW()
WHERE athlete_id = 'athlete-uuid';
```

### profiles table (updated averages):

```sql
UPDATE profiles SET
  strava_average_pace = 9.15,           -- min/km (from this + recent runs)
  weekly_mileage = 23.12,               -- km/week (23.12 km last 7 days)
  total_activities = 4,                 -- activities last 4 weeks
  last_sync = NOW()
WHERE id = 'athlete-uuid';
```

### Additional Wellness Data from Dashboard:

From the user's dashboard, we also see:

- **VO2 Max**: 37 ml/kg/min
- **Lactate Threshold**: 158 bpm, 6:40/km pace, 302W power
- **Resting HR**: 51 bpm (current), 54 bpm (7d avg)
- **HRV**: 72 ms (7d avg)
- **Sleep**: 5h 15m, score 60
- **Body Battery**: 54 (current), +53 charged, -27 drained
- **Stress**: 14 (current)
- **Training Status**: Unproductive since Feb 17
- **Training Load**: High (349 acute / 231 chronic, ratio 1.5)

These would be stored in separate API calls:

```dart
// Store from wellness API
await Supabase.instance.client.from('athlete_metrics').upsert({
  'athlete_id': athleteId,
  'vo2_max': 37.0,
  'lactate_threshold_hr': 158,
  'lactate_threshold_pace': 6.67, // 6:40/km
  'lactate_threshold_power': 302,
  'training_load': 349,
  'training_status': 'unproductive',
  'updated_at': DateTime.now().toIso8601String(),
});

await Supabase.instance.client.from('garmin_wellness_data').upsert({
  'athlete_id': athleteId,
  'date': '2026-02-26',
  'resting_hr': 51,
  'hrv_morning': 72, // From 7d avg
  'hrv_status': 'balanced',
  'sleep_score': 60,
  'sleep_duration_minutes': 315, // 5h 15m
  'body_battery': 54,
  'body_battery_charged': 53,
  'body_battery_drained': 27,
  'stress_level': 14,
  'steps': 12592,
  'updated_at': DateTime.now().toIso8601String(),
});
```

---

## 📊 Data Quality Insights from Real Example

### Good Indicators ✅

- **Consistent Cadence**: 146 spm (good for endurance pace)
- **GCT**: 290ms (typical for zone 2 running)
- **Vertical Oscillation**: 7.3cm (efficient)
- **Training Effect**: 3.6 (good aerobic stimulus)

### Areas for Improvement ⚠️

- **VO2 Max**: 37 ml/kg/min (below average for runner)
- **Sleep**: 5h 15m (insufficient, recommend 7-9h)
- **Training Status**: Unproductive (high load but fitness not improving)
- **Recovery**: Body Battery -20 impact suggests need for rest day

### How SafeStride Uses This Data:

1. **Pace Progression**: Current 9:09/km → 3:30/km timeline calculation
2. **AISRI Updates**: GCT, cadence, VO impact injury risk score
3. **Recovery Planning**: Sleep score + Body Battery → rest day recommendations
4. **Training Zones**: Lactate threshold (158 bpm, 6:40/km) sets zone TH workouts
5. **Progress Tracking**: Weekly mileage trending (23.12 km/week) → mileage progression safety

---

## � Garmin API vs ConnectIQ Watch App: Complete Data Comparison

### Option 1: Garmin Health API (Cloud-Based Integration)

**What You Get** (No watch app required):

#### ✅ Available via Health API

| Category             | Metrics Available                                                              | Real Example                 |
| -------------------- | ------------------------------------------------------------------------------ | ---------------------------- |
| **Activities**       | Distance, duration, pace, splits, HR, calories                                 | 8.48 km, 1:17:34, 9:09/km    |
| **Running Dynamics** | Cadence, GCT, vertical oscillation, stride length, GCT balance, vertical ratio | 146 spm, 290ms, 7.3cm, 0.73m |
| **Power Metrics**    | Average power, max power, power zones                                          | 205W avg, 336W max           |
| **Heart Rate**       | Average HR, max HR, resting HR, HR zones, HRV                                  | 140 avg, 164 max, 51 resting |
| **Elevation**        | Total ascent/descent, min/max elevation, grade                                 | 18m ascent, 23m descent      |
| **Sleep**            | Duration, stages (deep/light/REM/awake), score, quality                        | 5h 15m, 60 score             |
| **Wellness**         | Body Battery, stress level, respiration rate                                   | 54 battery, 14 stress        |
| **Training Metrics** | VO2 max, lactate threshold, training effect, exercise load                     | 37 VO2, 158 LT, 3.6 TE       |
| **Daily Activity**   | Steps, calories, floors, intensity minutes                                     | 12,592 steps, 628 cal        |
| **Recovery**         | Recovery time, training status, training load                                  | 19 readiness, unproductive   |

**API Endpoints**:

```
GET /wellness-api/rest/activityDetails/{activityId}     // Full activity data
GET /wellness-api/rest/user/v2/vo2Max                   // VO2 max history
GET /wellness-api/rest/runningDynamics/{activityId}     // Running dynamics
GET /wellness-api/rest/hrv/{date}                       // HRV data
GET /wellness-api/rest/dailySleep/{date}                // Sleep data
GET /wellness-api/rest/wellness/{date}                  // Daily wellness
GET /wellness-api/rest/bodyComposition/{date}           // Body metrics
GET /wellness-api/rest/bloodPressure/{date}             // Blood pressure
GET /wellness-api/rest/stressDetails/{date}             // Detailed stress
```

#### ❌ NOT Available via Health API

| Data Type                     | Why Not Available                  | Alternative          |
| ----------------------------- | ---------------------------------- | -------------------- |
| **Real-time AISRI score**     | Custom calculation not in Garmin   | Build ConnectIQ app  |
| **Live training protocol**    | Custom workout logic               | ConnectIQ data field |
| **SafeStride-specific zones** | Custom zone definitions            | ConnectIQ app        |
| **Custom lap triggers**       | Based on AISRI/biomechanics        | ConnectIQ app        |
| **Real-time form alerts**     | Custom alerts for GCT, VO, cadence | ConnectIQ app        |
| **Instantaneous metrics**     | Sub-second data capture            | ConnectIQ app        |

---

### Option 2: ConnectIQ Watch App (Custom App Development)

**When You Need This**:

- Real-time AISRI score display on watch
- Live coaching prompts during workout
- Custom zone alerts (not just HR zones)
- Instant biomechanics feedback
- Custom lap/interval triggers based on SafeStride logic

#### 📱 What ConnectIQ App Can Access

**Activity Module** (`Toybox.Activity`):

```monkey-c
// Real-time activity metrics (every second)
var info = Activity.getActivityInfo();

info.currentSpeed          // m/s (real-time)
info.currentHeartRate      // bpm (real-time)
info.currentCadence        // spm (real-time)
info.currentPower          // watts (real-time)
info.elapsedDistance       // meters
info.elapsedTime           // milliseconds
info.averageSpeed          // m/s
info.averageHeartRate      // bpm
info.currentLocationAccuracy // GPS accuracy
info.currentAltitude       // meters
info.totalAscent           // meters
info.totalDescent          // meters
```

**FitContributor Module** (Record custom data):

```monkey-c
// Store custom fields in FIT file
var aisriField = createField(
    "aisri_score",          // Field name
    0,                      // Field ID
    FitContributor.DATA_TYPE_UINT8,
    {:mesgType=>FitContributor.MESG_TYPE_RECORD}
);

// Record every second
aisriField.setData(calculatedAISRI); // Your AISRI calculation
```

**Sensor Module** (`Toybox.Sensor`):

```monkey-c
var sensorInfo = Sensor.getInfo();

sensorInfo.heartRate       // Current HR
sensorInfo.cadence         // Current cadence
sensorInfo.speed           // Current speed
sensorInfo.altitude        // Current altitude
sensorInfo.pressure        // Barometric pressure
sensorInfo.temperature     // Temperature
```

**Running Dynamics** (on compatible watches):

```monkey-c
var rdInfo = Activity.getActivityInfo();

rdInfo.currentGroundContactTime        // ms
rdInfo.currentGroundContactBalance     // %
rdInfo.currentVerticalOscillation      // cm
rdInfo.currentVerticalRatio            // %
rdInfo.currentStrideLength             // meters
```

#### 🎯 SafeStride ConnectIQ App Data Field Example

**Real-time Data Display on Watch**:

```
╔════════════════════════════╗
║   SafeStride AISRI v1.0   ║
╠════════════════════════════╣
║  AISRI Score:    73  🟢    ║
║  Target Zone:    EN        ║
║  Current GCT:    285 ms ✓  ║
║  Cadence:        148 spm ✓ ║
║  HR Zone:        143 (TH)  ║
║  Form Alert:     GOOD      ║
╚════════════════════════════╝
```

**Code Structure** (`SafeStrideDataField.mc`):

```monkey-c
using Toybox.WatchUi;
using Toybox.Activity;
using Toybox.FitContributor;

class SafeStrideDataField extends WatchUi.DataField {

    hidden var mAisriField;
    hidden var mCurrentAISRI;

    function initialize() {
        DataField.initialize();

        // Create custom FIT field for AISRI
        mAisriField = createField(
            "aisri_score",
            0,
            FitContributor.DATA_TYPE_UINT8,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD}
        );
    }

    function compute(info) {
        // Calculate AISRI from real-time metrics
        var gct = info.currentGroundContactTime;
        var cadence = info.currentCadence;
        var vo = info.currentVerticalOscillation;
        var hr = info.currentHeartRate;

        if (gct != null && cadence != null) {
            mCurrentAISRI = calculateAISRI(gct, cadence, vo, hr);
            mAisriField.setData(mCurrentAISRI); // Store in FIT file
        }
    }

    function calculateAISRI(gct, cadence, vo, hr) {
        // Your AISRI calculation logic
        var gctScore = 100;

        // GCT scoring (ideal: 250-280ms)
        if (gct > 320) {
            gctScore = 40;  // Poor
        } else if (gct > 300) {
            gctScore = 60;  // Fair
        } else if (gct >= 250 && gct <= 280) {
            gctScore = 100; // Excellent
        } else if (gct >= 220) {
            gctScore = 80;  // Good
        } else {
            gctScore = 50;  // Too short
        }

        // Cadence scoring (ideal: 165-180 spm)
        var cadenceScore = 100;
        if (cadence < 150) {
            cadenceScore = 50;
        } else if (cadence >= 165 && cadence <= 180) {
            cadenceScore = 100;
        } else if (cadence > 180) {
            cadenceScore = 80;
        }

        // Combine scores (simplified)
        return (gctScore + cadenceScore) / 2;
    }

    function onUpdate(dc) {
        // Display AISRI on watch screen
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var aisriText = mCurrentAISRI != null ?
            mCurrentAISRI.format("%d") : "--";

        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_LARGE,
            "AISRI: " + aisriText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
```

#### 📦 Complete SafeStride Watch App Features

**1. Data Field** (Shows AISRI during run):

- Real-time AISRI score
- Current training zone indication
- Form quality alerts

**2. Widget** (Home screen summary):

- Today's AISRI trend
- Recovery status
- Next workout recommendation

**3. App** (Full interface):

- Pre-run protocol selection
- Live coaching during workout
- Post-run AISRI analysis

**4. Custom FIT Fields** (Recorded every second):

```monkey-c
- aisri_score (0-100)
- target_zone (EN/TH/P)
- form_quality (0-100)
- gct_deviation (ms from ideal)
- cadence_deviation (spm from ideal)
- hr_zone_compliance (% time in target)
```

---

### 📊 Complete Data Comparison Table

| Metric                   | Garmin API | ConnectIQ App | Frequency     | Use Case     |
| ------------------------ | ---------- | ------------- | ------------- | ------------ |
| **Distance**             | ✅         | ✅            | Real-time     | Both         |
| **Pace**                 | ✅         | ✅            | Real-time     | Both         |
| **Heart Rate**           | ✅         | ✅            | Per second    | Both         |
| **Cadence**              | ✅         | ✅            | Per second    | Both         |
| **Ground Contact Time**  | ✅         | ✅            | Per second    | Both         |
| **Vertical Oscillation** | ✅         | ✅            | Per second    | Both         |
| **Stride Length**        | ✅         | ✅            | Per second    | Both         |
| **Power**                | ✅         | ✅            | Per second    | Both         |
| **VO2 Max**              | ✅         | ❌            | Post-activity | API only     |
| **Sleep Data**           | ✅         | ❌            | Daily         | API only     |
| **Body Battery**         | ✅         | ❌            | Continuous    | API only     |
| **HRV**                  | ✅         | ❌            | Daily         | API only     |
| **Training Effect**      | ✅         | ❌            | Post-activity | API only     |
| **AISRI Score**          | ❌         | ✅            | Real-time     | App required |
| **Custom Zones**         | ❌         | ✅            | Real-time     | App required |
| **Form Alerts**          | ❌         | ✅            | Real-time     | App required |
| **Protocol Coach**       | ❌         | ✅            | Real-time     | App required |
| **Instant Feedback**     | ❌         | ✅            | Sub-second    | App required |

---

### 🎯 Recommendation for SafeStride

#### Phase 1: Start with Garmin Health API (Recommended) ✅

**Why**:

- ✅ **95% of needed data available** without custom app
- ✅ **No development effort** on watch platform
- ✅ **Works on ALL Garmin devices** (no device compatibility issues)
- ✅ **Immediate integration** (just OAuth + API calls)
- ✅ **Historical data access** (sleep, wellness, past activities)
- ✅ **Comprehensive metrics** (VO2, LT, training status, recovery)

**What You Get**:

```
POST-WORKOUT ANALYSIS (via API):
✅ Complete running dynamics (GCT, cadence, VO, stride)
✅ Full activity details (pace, HR, power, splits)
✅ Calculate AISRI from recorded data
✅ Generate injury risk assessment
✅ Update training plan based on performance
✅ Integrate wellness metrics (sleep, recovery, HRV)
✅ Track progress over time
```

**Implementation**:

```dart
// Simple API integration - no watch app needed
final garminService = GarminSyncService();
await garminService.connectAndSync(athleteId);

// Automatic daily sync
await garminService.syncRecentActivities();

// All metrics available for analysis
final aisri = AISRICalculator.fromGarminActivity(activityData);
```

#### Phase 2: Build ConnectIQ App (Optional Enhancement) 🎯

**When to Build**:

- Athletes request real-time AISRI on watch
- Need live coaching during workout
- Want instant form correction alerts
- Require custom lap/interval triggers

**Development Effort**:

- **Data Field**: 2-3 weeks (shows AISRI during run)
- **Widget**: 1-2 weeks (home screen summary)
- **Full App**: 4-6 weeks (complete workout guidance)

**Technologies**:

- Language: Monkey C (Garmin's language)
- IDE: Visual Studio Code with ConnectIQ SDK
- Testing: Garmin Simulator + real device
- Distribution: Garmin Connect IQ Store

**Sample Workflow with ConnectIQ App**:

```
1. Athlete opens SafeStride app on watch
2. Selects protocol (e.g., "Zone TH Intervals")
3. During run:
   - Watch displays real-time AISRI
   - Alerts if GCT > 300ms ("Reduce ground contact!")
   - Alerts if cadence < 165 ("Increase turnover!")
   - Shows current zone (EN/TH/P)
4. Post-run:
   - FIT file includes custom AISRI data
   - Sync to Garmin Connect → SafeStride
   - Full analysis with AISRI trends
```

---

### 💾 Data Storage with Both Approaches

#### API-Only Approach:

```sql
-- Post-activity analysis
INSERT INTO garmin_activities (
  athlete_id, distance, average_pace,
  avg_cadence, gct, vertical_oscillation
) VALUES (
  'uuid', 8480, 9.15,
  146, 290, 7.3
);

-- Calculate AISRI after sync
UPDATE athlete_metrics SET
  aisri_score = calculate_aisri(avg_cadence, gct, vo),
  updated_at = NOW()
WHERE athlete_id = 'uuid';
```

#### API + ConnectIQ Approach:

```sql
-- Real-time AISRI captured every second
INSERT INTO aisri_timeseries (
  athlete_id, activity_id, timestamp,
  aisri_score, gct, cadence, vertical_oscillation
) VALUES
  ('uuid', 'activity-1', '2026-02-26 00:57:01', 73, 285, 148, 7.2),
  ('uuid', 'activity-1', '2026-02-26 00:57:02', 75, 280, 150, 7.1),
  ('uuid', 'activity-1', '2026-02-26 00:57:03', 74, 282, 149, 7.0),
  -- ... 4654 records (every second of run)

-- Enables detailed analysis:
-- - AISRI degradation patterns (when does form break down?)
-- - Zone-specific biomechanics (GCT in EN vs TH vs P zones)
-- - Fatigue indicators (how GCT/cadence change over time)
-- - Interval quality assessment (form maintenance during hard efforts)
```

---

### 📝 Summary: What Data You'll Get

**With Garmin Health API (No Watch App)**:

- ✅ Complete post-workout analysis
- ✅ All running dynamics (GCT, cadence, VO, stride, power)
- ✅ Wellness metrics (sleep, HRV, Body Battery, stress)
- ✅ Training metrics (VO2 max, lactate threshold, training effect)
- ✅ Activity history (unlimited past activities)
- ❌ Real-time AISRI display on watch
- ❌ Live coaching during workout
- ❌ Instant form alerts

**With ConnectIQ App (Custom Development)**:

- ✅ All API data (still need API for wellness/historical)
- ✅ Real-time AISRI on watch screen
- ✅ Live form correction alerts
- ✅ Custom zone guidance during run
- ✅ Second-by-second AISRI recording
- ✅ Custom lap triggers based on biomechanics
- ⚠️ Requires development effort (2-6 weeks)
- ⚠️ Device compatibility testing needed

**Recommendation**: **Start with API only**, add ConnectIQ app later if users demand real-time features.

---

## �🚀 Next Steps

1. **Set up Garmin Developer Account**: https://developer.garmin.com
2. **Get OAuth credentials**: Consumer Key + Consumer Secret
3. **Implement OAuth 1.0a flow** in your app
4. **Test with real Garmin data** using your own device
5. **Create database tables** (run SQL from this guide)
6. **Implement sync service** (copy code examples)
7. **Set up daily sync scheduler** (WorkManager or similar)

---

**All data formats, transformations, and storage schemas are now documented!** 🎉
