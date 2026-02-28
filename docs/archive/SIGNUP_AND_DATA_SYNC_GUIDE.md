# SafeStride Signup & Data Sync Guide 🔄

## Overview

This guide explains the complete signup process and how SafeStride continuously syncs data from Garmin and Strava to keep your training metrics up-to-date.

---

## 📱 Complete Signup Flow

### Step 1: Initial Account Creation

**Screen**: `lib/screens/auth/signup_screen.dart`

```
User arrives → Sees two options:
├─ 🟠 Sign Up with Strava (Recommended)
└─ 📧 Sign Up with Email
```

### Step 2A: Strava OAuth Signup (Recommended Path)

**Why Strava First?**

- ✅ Auto-fills name, age, email, profile photo
- ✅ Instant access to activity history (100-1000+ activities)
- ✅ Gets current pace, weekly mileage, training zones
- ✅ No duplicate data entry

**Flow**:

```
1. User clicks [Sign Up with Strava]
   ↓
2. Redirect to Strava OAuth
   URL: https://www.strava.com/oauth/authorize
   Params:
   - client_id: YOUR_STRAVA_CLIENT_ID
   - redirect_uri: safestride://auth/callback
   - response_type: code
   - scope: read,activity:read_all,profile:read_all
   ↓
3. User authorizes on Strava
   ↓
4. Callback to app with auth code
   ↓
5. Exchange code for access token
   ↓
6. Fetch Strava profile data:
   - firstname, lastname
   - profile photo
   - email (if shared)
   - athlete ID
   ↓
7. Create account with pre-filled data
   ↓
8. Save Strava credentials to database
   ↓
9. START BACKGROUND SYNC (see below)
   ↓
10. Navigate to Evaluation Form
```

**Code Example**:

```dart
// lib/services/strava_service.dart
class StravaService {
  static Future<void> signupWithStrava() async {
    // 1. Get OAuth code
    final code = await _getStravaAuthCode();

    // 2. Exchange for access token
    final tokens = await _exchangeCodeForTokens(code);

    // 3. Fetch athlete profile
    final profile = await _fetchAthleteProfile(tokens.accessToken);

    // 4. Create SafeStride account
    final user = await Supabase.instance.client.auth.signUp(
      email: profile.email,
      password: _generateSecurePassword(),
    );

    // 5. Save profile with Strava data
    await Supabase.instance.client.from('profiles').insert({
      'id': user.user!.id,
      'strava_athlete_id': profile.id,
      'strava_access_token': tokens.accessToken,
      'strava_refresh_token': tokens.refreshToken,
      'strava_token_expires_at': tokens.expiresAt,
      'first_name': profile.firstname,
      'last_name': profile.lastname,
      'email': profile.email,
      'profile_photo': profile.profile,
      'strava_average_pace': profile.recentPace,
      'weekly_mileage': profile.weeklyDistance,
    });

    // 6. Start background sync
    await StravaBackgroundSyncService.startSync(user.user!.id);

    // 7. Navigate to evaluation
    Navigator.pushNamed(context, '/evaluation');
  }
}
```

### Step 2B: Email Signup (Manual Path)

**Flow**:

```
1. User enters email, password
   ↓
2. Create account with Supabase Auth
   ↓
3. User manually enters:
   - Name
   - Age
   - Gender
   - (Optional) Connect Strava later
   ↓
4. Navigate to Evaluation Form
```

---

## 🔄 Background Data Sync System

### Architecture

```
┌─────────────────────────────────────────────────┐
│              SafeStride App                     │
│  ┌──────────────────────────────────────────┐  │
│  │        Main UI Thread                    │  │
│  │   (User continues evaluation form)       │  │
│  └──────────────────────────────────────────┘  │
│                      │                          │
│                      │ Spawns Isolate           │
│                      ↓                          │
│  ┌──────────────────────────────────────────┐  │
│  │    Background Sync Isolate               │  │
│  │  • Fetches activities from Strava        │  │
│  │  • Fetches data from Garmin              │  │
│  │  • Saves to database                     │  │
│  │  • Updates progress notifications        │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
         │                          │
         │ API Calls                │ API Calls
         ↓                          ↓
┌──────────────────┐      ┌──────────────────┐
│   Strava API     │      │   Garmin API     │
│  (Activities)    │      │ (Wellness Data)  │
└──────────────────┘      └──────────────────┘
```

### Strava Background Sync

**File**: `lib/services/strava_background_sync.dart`

**What It Syncs**:

- ✅ All running activities (distance, pace, time)
- ✅ Heart rate data (average, max, zones)
- ✅ Elevation gain/loss
- ✅ Splits and laps
- ✅ Achievement count (PRs, KOMs)
- ✅ Training load and intensity

**Implementation**:

```dart
// lib/services/strava_background_sync.dart
import 'dart:isolate';

class StravaBackgroundSyncService {
  static Future<void> startSync(String userId) async {
    // Show initial notification
    await _showNotification('Syncing Strava activities...');

    // Spawn isolate for background work
    await Isolate.spawn(_syncActivitiesIsolate, {
      'userId': userId,
      'sendPort': receivePort.sendPort,
    });

    // Listen for progress updates
    receivePort.listen((message) {
      if (message['type'] == 'progress') {
        _updateNotification('Synced ${message['count']} activities...');
      } else if (message['type'] == 'complete') {
        _showNotification('✅ Synced ${message['total']} activities!');
      }
    });
  }

  static Future<void> _syncActivitiesIsolate(Map<String, dynamic> data) async {
    final userId = data['userId'];
    final sendPort = data['sendPort'] as SendPort;

    // Get Strava credentials
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('strava_access_token, strava_refresh_token')
        .eq('id', userId)
        .single();

    // Refresh token if expired
    await _ensureValidToken(profile);

    // Fetch activities in pages (200 per page)
    int page = 1;
    int totalSynced = 0;

    while (true) {
      final activities = await _fetchActivityPage(
        accessToken: profile['strava_access_token'],
        page: page,
        perPage: 200,
      );

      if (activities.isEmpty) break;

      // Save to database
      await _saveActivitiesToDatabase(userId, activities);

      totalSynced += activities.length;

      // Send progress update
      sendPort.send({
        'type': 'progress',
        'count': totalSynced,
      });

      page++;
    }

    // Calculate summary stats
    await _calculateTrainingStats(userId);

    // Send completion message
    sendPort.send({
      'type': 'complete',
      'total': totalSynced,
    });
  }

  static Future<void> _calculateTrainingStats(String userId) async {
    // Calculate from last 4 weeks of data
    final fourWeeksAgo = DateTime.now().subtract(Duration(days: 28));

    final stats = await Supabase.instance.client
        .from('strava_activities')
        .select('distance, moving_time, average_speed')
        .eq('athlete_id', userId)
        .gte('start_date', fourWeeksAgo.toIso8601String());

    // Calculate averages
    final totalDistance = stats.fold(0.0, (sum, a) => sum + (a['distance'] / 1000));
    final avgPace = _calculateAveragePace(stats);
    final weeklyMileage = totalDistance / 4;

    // Update profile
    await Supabase.instance.client.from('profiles').update({
      'strava_average_pace': avgPace,
      'weekly_mileage': weeklyMileage,
      'total_activities': stats.length,
      'last_sync': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
```

### Garmin Connect Integration

**File**: `lib/services/garmin_sync_service.dart`

**What It Syncs**:

- ✅ Activities (running, cycling, swimming)
- ✅ Daily wellness data:
  - Resting heart rate
  - HRV (heart rate variability)
  - Sleep stages and quality
  - Stress levels
  - Body Battery
  - Steps and active calories
- ✅ Advanced running metrics:
  - VO2 Max
  - Lactate Threshold
  - Ground Contact Time (GCT)
  - Vertical Oscillation
  - Stride Length
  - Cadence
  - Left/Right Balance

**OAuth Flow**:

```
1. User clicks [Connect Garmin]
   ↓
2. Redirect to Garmin OAuth
   URL: https://connect.garmin.com/oauthConfirm
   ↓
3. User authorizes
   ↓
4. Callback with OAuth tokens
   ↓
5. Save credentials
   ↓
6. Start background wellness data sync
   ↓
7. Fetch historical activities
   ↓
8. Set up daily sync schedule
```

**Implementation**:

```dart
// lib/services/garmin_sync_service.dart
class GarminSyncService {
  static Future<void> connectAndSync(String userId) async {
    // 1. OAuth flow
    final tokens = await _performGarminOAuth();

    // 2. Save credentials
    await Supabase.instance.client.from('profiles').update({
      'garmin_access_token': tokens.accessToken,
      'garmin_access_secret': tokens.accessSecret,
      'garmin_connected': true,
    }).eq('id', userId);

    // 3. Start background sync
    await _startBackgroundWellnessSync(userId);
  }

  static Future<void> _startBackgroundWellnessSync(String userId) async {
    await Isolate.spawn(_syncGarminData, {
      'userId': userId,
      'syncTypes': ['activities', 'wellness', 'metrics'],
    });
  }

  static Future<void> _syncGarminData(Map<String, dynamic> data) async {
    final userId = data['userId'];

    // Get Garmin credentials
    final profile = await _getGarminCredentials(userId);

    // Sync activities
    await _syncGarminActivities(profile);

    // Sync wellness data (daily)
    await _syncDailyWellnessData(profile);

    // Sync advanced metrics
    await _syncAdvancedRunningMetrics(profile);
  }

  static Future<void> _syncAdvancedRunningMetrics(profile) async {
    // Fetch running dynamics
    final metrics = await _fetchGarminMetrics(
      accessToken: profile['garmin_access_token'],
      types: ['vo2max', 'lactateThreshold', 'runningDynamics'],
    );

    await Supabase.instance.client.from('athlete_metrics').upsert({
      'athlete_id': profile['id'],
      'vo2_max': metrics['vo2max'],
      'lactate_threshold_hr': metrics['lactateThresholdHR'],
      'lactate_threshold_pace': metrics['lactateThresholdPace'],
      'gct_balance': metrics['gctBalance'],
      'vertical_oscillation': metrics['verticalOscillation'],
      'stride_length': metrics['strideLength'],
      'avg_cadence': metrics['avgCadence'],
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
```

---

## 🔁 Continuous Sync Strategy

### Daily Automatic Sync

**Trigger Points**:

1. **App Launch** - Sync on every app open
2. **Scheduled** - Daily at 3 AM (background task)
3. **After Workout** - Webhook from Strava/Garmin
4. **Manual** - User clicks "Sync Now" button

**Implementation**:

```dart
// lib/services/sync_scheduler.dart
class SyncScheduler {
  static Future<void> initialize(String userId) async {
    // 1. Sync on app launch
    await _syncOnLaunch(userId);

    // 2. Schedule daily sync
    await _scheduleDailySync(userId);

    // 3. Register webhook listener
    await _registerWebhookListener(userId);
  }

  static Future<void> _syncOnLaunch(String userId) async {
    // Check last sync time
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('last_sync')
        .eq('id', userId)
        .single();

    final lastSync = DateTime.parse(profile['last_sync'] ?? '2000-01-01');
    final hoursSinceSync = DateTime.now().difference(lastSync).inHours;

    // Sync if > 6 hours since last sync
    if (hoursSinceSync >= 6) {
      await _performFullSync(userId);
    }
  }

  static Future<void> _scheduleDailySync(String userId) async {
    // Use Flutter WorkManager for background tasks
    await Workmanager().registerPeriodicTask(
      'daily-sync',
      'dailySyncTask',
      frequency: Duration(hours: 24),
      initialDelay: _getNextSyncTime(), // 3 AM tomorrow
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> _performFullSync(String userId) async {
    try {
      // Sync Strava
      if (await _hasStravaConnection(userId)) {
        await StravaBackgroundSyncService.syncRecentActivities(userId);
      }

      // Sync Garmin
      if (await _hasGarminConnection(userId)) {
        await GarminSyncService.syncRecentData(userId);
      }

      // Recalculate AISRI with new data
      await _recalculateAISRI(userId);

      // Update progression plan if needed
      await _updateProgressionPlan(userId);

    } catch (e) {
      print('Sync error: $e');
      // Log to error tracking service
    }
  }
}
```

### Webhook Integration (Real-Time Sync)

**Strava Webhook**:

```dart
// When Strava POSTs new activity notification
Future<void> handleStravaWebhook(Map<String, dynamic> webhook) async {
  if (webhook['aspect_type'] == 'create' &&
      webhook['object_type'] == 'activity') {

    final athleteId = webhook['owner_id'];
    final activityId = webhook['object_id'];

    // Find user by Strava athlete ID
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('id, strava_access_token')
        .eq('strava_athlete_id', athleteId)
        .maybeSingle();

    if (profile != null) {
      // Fetch and save new activity
      await _fetchAndSaveActivity(
        profile['id'],
        activityId,
        profile['strava_access_token'],
      );

      // Send push notification
      await _sendNotification(
        profile['id'],
        'New activity synced! 🏃',
        'Your latest workout has been added to SafeStride',
      );
    }
  }
}
```

---

## 📊 Data Storage Schema

### profiles table

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),

  -- Basic info
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  age INTEGER,

  -- Strava connection
  strava_athlete_id BIGINT,
  strava_access_token TEXT,
  strava_refresh_token TEXT,
  strava_token_expires_at TIMESTAMPTZ,
  strava_connected BOOLEAN DEFAULT FALSE,

  -- Garmin connection
  garmin_access_token TEXT,
  garmin_access_secret TEXT,
  garmin_connected BOOLEAN DEFAULT FALSE,

  -- Calculated metrics
  strava_average_pace DECIMAL(5,2), -- seconds per km
  weekly_mileage DECIMAL(6,2), -- km per week
  total_activities INTEGER,
  aisri_score INTEGER,

  -- Sync status
  last_sync TIMESTAMPTZ,
  sync_in_progress BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### strava_activities table

```sql
CREATE TABLE strava_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  strava_activity_id BIGINT UNIQUE,

  name TEXT,
  type TEXT, -- 'Run', 'Ride', etc.
  start_date TIMESTAMPTZ,
  distance DECIMAL(10,2), -- meters
  moving_time INTEGER, -- seconds
  elapsed_time INTEGER,

  average_speed DECIMAL(5,2), -- m/s
  max_speed DECIMAL(5,2),
  average_heartrate DECIMAL(5,1),
  max_heartrate INTEGER,

  total_elevation_gain DECIMAL(10,2),
  calories DECIMAL(10,2),

  -- Advanced metrics
  splits JSONB, -- Lap/split data
  laps JSONB,
  heartrate_zones JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### garmin_wellness_data table

```sql
CREATE TABLE garmin_wellness_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),
  date DATE,

  -- Heart metrics
  resting_hr INTEGER,
  hrv_morning INTEGER, -- ms

  -- Sleep
  sleep_score INTEGER, -- 0-100
  sleep_duration_minutes INTEGER,
  deep_sleep_minutes INTEGER,
  light_sleep_minutes INTEGER,
  rem_sleep_minutes INTEGER,
  awake_minutes INTEGER,

  -- Wellness
  stress_level INTEGER, -- 0-100
  body_battery INTEGER, -- 0-100
  recovery_time INTEGER, -- hours

  -- Activity
  steps INTEGER,
  active_calories INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(athlete_id, date)
);
```

### athlete_metrics table (Advanced Garmin Data)

```sql
CREATE TABLE athlete_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  athlete_id UUID REFERENCES profiles(id),

  -- Fitness estimates
  vo2_max DECIMAL(4,1),
  vo2_max_timestamp TIMESTAMPTZ,

  -- Threshold data
  lactate_threshold_hr INTEGER,
  lactate_threshold_pace DECIMAL(5,2), -- min/km

  -- Running dynamics
  gct_balance DECIMAL(5,2), -- % left
  vertical_oscillation DECIMAL(5,2), -- cm
  stride_length DECIMAL(5,2), -- meters
  avg_cadence INTEGER, -- steps per minute
  vertical_ratio DECIMAL(5,2), -- cm per meter

  -- Training status
  training_load INTEGER,
  training_effect DECIMAL(3,1),
  training_status TEXT, -- 'Productive', 'Detraining', etc.

  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🔔 User Notifications

### Sync Progress Notifications

**During signup**:

```dart
// Show progress as sync happens
await showNotification(
  title: 'Syncing your data...',
  body: 'Fetching 908 activities from Strava',
  progress: 0.5, // 50%
);

// Update periodically
await updateNotification(
  title: 'Almost done!',
  body: '700 of 908 activities synced',
  progress: 0.77,
);

// Completion
await showNotification(
  title: '✅ Sync complete!',
  body: '908 activities synced. Ready to calculate your journey to 3:30/km!',
);
```

### Daily Sync Notifications

```dart
// After daily background sync
await showNotification(
  title: '🔄 Activities updated',
  body: '3 new workouts synced from Strava',
  action: 'View Activities',
);
```

---

## 🎯 User Experience Flow

### Optimal Onboarding (Strava Path):

```
1. User opens app → Signup screen
   ⏱️ 0 seconds

2. User clicks [Sign Up with Strava]
   ⏱️ 5 seconds

3. Strava OAuth → Authorize
   ⏱️ 10 seconds

4. Return to app → Account created
   Profile auto-filled (name, photo, email)
   ⏱️ 12 seconds

5. Background sync starts (908 activities)
   User sees: "Syncing activities in background..."
   User proceeds to evaluation form
   ⏱️ 15 seconds

6. User completes evaluation (18 questions)
   Sync continues in background
   ⏱️ 3-5 minutes

7. AISRI calculated, results shown
   Sync complete! ✅
   ⏱️ 5 minutes

8. Click [View Your Journey]
   Timeline calculated with REAL Strava data:
   • Current pace: 6:15/km (from last 4 weeks)
   • Weekly mileage: 42 km
   • Timeline: 18 weeks to 3:30/km
   ⏱️ 5 minutes 10 seconds
```

**NO duplicate data entry!**  
**NO waiting for sync!**  
**Seamless experience!** ✨

---

## 🛠️ Testing the Sync System

### Manual Test

1. **Create test account with Strava**
2. **Check database** - Verify profile saved with Strava data
3. **Monitor sync progress** - Watch notifications
4. **Check strava_activities table** - Verify activities synced
5. **Calculate timeline** - Should use real pace/mileage

### Automated Test

```dart
// test/services/strava_sync_test.dart
void main() {
  test('Strava signup and sync', () async {
    // 1. Mock Strava OAuth
    final mockProfile = MockStravaProfile(
      id: 12345,
      firstname: 'Test',
      lastname: 'Runner',
      email: 'test@example.com',
    );

    // 2. Perform signup
    final user = await StravaService.signupWithStrava(mockProfile);

    // 3. Verify profile created
    expect(user.id, isNotNull);

    // 4. Verify background sync started
    await Future.delayed(Duration(seconds: 5));
    final syncStatus = await _checkSyncStatus(user.id);
    expect(syncStatus.inProgress, true);

    // 5. Wait for sync completion
    await _waitForSyncCompletion(user.id);

    // 6. Verify activities synced
    final activities = await _getActivities(user.id);
    expect(activities.length, greaterThan(0));
  });
}
```

---

## 📝 Checklist for Implementation

### Strava Integration

- [ ] OAuth flow implemented
- [ ] Token refresh logic
- [ ] Background sync isolate
- [ ] Activity pagination (200 per page)
- [ ] Stats calculation
- [ ] Error handling
- [ ] Webhook subscription

### Garmin Integration

- [ ] OAuth flow implemented
- [ ] Wellness data sync
- [ ] Advanced metrics sync
- [ ] Daily sync scheduler
- [ ] Token management

### User Experience

- [ ] Progress notifications
- [ ] Sync status indicator
- [ ] Manual sync button
- [ ] Connection management screen
- [ ] Data refresh on app launch

### Database

- [ ] Tables created (profiles, activities, wellness, metrics)
- [ ] Indexes optimized
- [ ] RLS policies configured

---

## 🚀 Next Steps

1. **Test the aligned cards**: http://localhost:8080/test-timeline-calculator.html
2. **Review this guide** and confirm the flow makes sense
3. **Implement background sync service** if not already done
4. **Set up Garmin OAuth** if planning to support it
5. **Test end-to-end** with real Strava account

---

**Questions? Ready to implement? Let me know!** 🎉
