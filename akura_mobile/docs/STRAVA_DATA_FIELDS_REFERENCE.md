# Strava Data Fields - Complete Reference

## 📊 All Data Captured from Strava Activities

This document lists ALL data fields now captured from Strava and stored in the database for AISRI injury risk analysis.

---

## 🏃 BIOMECHANICAL METRICS

### Cadence
- **Field**: `avg_cadence`, `max_cadence`
- **Unit**: Steps per minute (spm)
- **Note**: Strava API reports HALF cadence (one foot), we automatically multiply by 2 to get full cadence
- **Use**: Optimal running cadence is 170-180 spm for injury prevention

### Stride Length
- **Field**: `avg_stride_length`
- **Unit**: Meters per step
- **Calculation**: `Speed (m/s) / (Cadence (steps/s))`
- **Use**: Shorter, quicker strides reduce impact force

### Ground Contact Time
- **Field**: `avg_ground_contact_time`
- **Unit**: Milliseconds (ms)
- **Typical Range**: 200-300 ms
- **Use**: Shorter GCT indicates more efficient running form

### Vertical Oscillation
- **Field**: `avg_vertical_oscillation`
- **Unit**: Centimeters (cm)
- **Typical Range**: 6-13 cm
- **Use**: Less vertical movement = more forward propulsion efficiency

### Vertical Ratio
- **Field**: `avg_vertical_ratio`
- **Unit**: Percentage (%)
- **Calculation**: Vertical Oscillation / Stride Length × 100
- **Use**: Lower ratio indicates more efficient form

---

## ❤️ CARDIOVASCULAR METRICS

### Heart Rate
- **Fields**: 
  - `avg_heart_rate` - Average Heart Rate (bpm)
  - `max_heart_rate` - Maximum Heart Rate (bpm)
- **Use**: Training intensity monitoring

### Heart Rate Zones (Time in Each Zone)
All stored in seconds:
- **Zone 1** (`hr_zone_1_seconds`): Recovery (50-60% max HR)
- **Zone 2** (`hr_zone_2_seconds`): Aerobic (60-70% max HR)
- **Zone 3** (`hr_zone_3_seconds`): Tempo (70-80% max HR)
- **Zone 4** (`hr_zone_4_seconds`): Threshold (80-90% max HR)
- **Zone 5** (`hr_zone_5_seconds`): Anaerobic (90-100% max HR)

**Use**: 
- Zone 2 builds aerobic base
- Zone 3-4 for tempo/threshold training
- Zone 5 for high-intensity intervals
- Balanced training reduces injury risk

---

## 🏃 PERFORMANCE METRICS

### Speed
- **Fields**:
  - `avg_speed` - Average Speed (km/h)
  - `max_speed` - Maximum Speed (km/h)
- **Use**: Track performance improvements over time

### Pace
- **Field**: `avg_pace`
- **Unit**: Minutes per kilometer (min/km)
- **Calculation**: Duration (min) / Distance (km)
- **Use**: Standard running metric

### Distance
- **Field**: `distance_meters`
- **Unit**: Meters
- **Display**: Usually converted to kilometers (km)

### Duration
- **Fields**:
  - `duration_seconds` - Total duration
  - `moving_time_seconds` - Time spent moving (excludes stops)
  - `elapsed_time_seconds` - Total elapsed time (includes stops)
- **Use**: Accurate training load calculation

---

## ⛰️ ELEVATION METRICS

### Elevation Changes
- **Fields**:
  - `elevation_gain` - Total meters climbed
  - `elevation_loss` - Total meters descended
  - `max_elevation` - Highest point reached
  - `min_elevation` - Lowest point reached
- **Unit**: Meters
- **Use**: Hilly terrain increases training load and injury risk

---

## ⚡ TRAINING EFFECT & ENERGY

### Training Load
- **Field**: `training_load` (Strava calls it `suffer_score`)
- **Range**: 0-100+
- **Use**: Quantifies workout intensity, higher = more stressful

### Training Effect
- **Fields**:
  - `aerobic_training_effect` - Impact on aerobic fitness (0-5)
  - `anaerobic_training_effect` - Impact on anaerobic fitness (0-5)
- **Typical**: 
  - 1.0-1.9: Minor benefit
  - 2.0-2.9: Maintaining
  - 3.0-3.9: Improving
  - 4.0-5.0: Highly improving

### Energy Expenditure
- **Fields**:
  - `calories` - Energy burned (kcal)
  - `avg_watts` - Average power output (Watts)
  - `max_watts` - Maximum power output (Watts)
  - `kilojoules` - Total energy (kJ)
- **Use**: Track energy systems and recovery needs

---

## 📅 CALENDAR DATE-WISE ORGANIZATION

### Date Storage
- **Field**: `start_time`
- **Type**: TIMESTAMPTZ (timestamp with timezone)
- **Indexed**: Yes (for fast queries)
- **Format**: ISO 8601 (e.g., "2024-12-15T08:30:00Z")

### Query by Date Range
```dart
// Get all activities for December 2024
final activities = await gpsDataFetcher.getActivitiesByDateRange(
  startDate: DateTime(2024, 12, 1),
  endDate: DateTime(2024, 12, 31),
);

// Returns: Map<DateTime, List<GPSActivity>>
// Example: {
//   2024-12-01: [activity1, activity2],
//   2024-12-05: [activity3],
//   2024-12-10: [activity4, activity5, activity6],
// }
```

### Calendar Use Cases
- **Weekly Training Load**: Sum all activities per week
- **Monthly Distance**: Total kilometers per month
- **Rest Days**: Identify dates with no activities
- **Peak Training Days**: Days with multiple activities
- **Injury Timeline**: Correlate symptoms with training dates

---

## 🗄️ DATABASE STRUCTURE

### Table: `gps_activities`

**Primary Key**: `id` (UUID)

**User Identification**:
- `user_id` - References auth.users
- `athlete_id` - Platform-specific athlete ID

**Platform Info**:
- `platform` - 'strava', 'garmin', or 'coros'
- `platform_activity_id` - Original activity ID from platform

**Activity Details**:
- `activity_type` - 'Run', 'TrailRun', etc.
- `activity_name` - Custom name
- `start_time` - When activity started (INDEXED)
- All metrics listed above...

**Raw Data**:
- `raw_data` - Complete JSON from Strava API (JSONB with GIN index)
- Preserves ALL original data for future analysis

**Metadata**:
- `synced_at` - When data was fetched from Strava
- `created_at` - Database record creation
- `updated_at` - Last modification

---

## 🔍 AISRI INJURY RISK ANALYSIS

### Key Metrics for Injury Prevention

**High Priority**:
1. **Weekly Training Load**: Sudden increases = higher injury risk
2. **Cadence**: Low cadence (<160 spm) = higher impact forces
3. **Stride Length**: Over-striding = increased injury risk
4. **Training Load Ratio**: Current week / Previous 4-week average
   - Safe: 0.8-1.3
   - Caution: 1.3-1.5
   - Danger: >1.5

**Moderate Priority**:
5. **Vertical Oscillation**: High = inefficient, more fatigue
6. **Ground Contact Time**: High = potential overstriding
7. **Heart Rate Zones**: Too much Zone 5 = inadequate recovery
8. **Elevation**: Steep hills increase load

**Supporting Data**:
9. **Rest Days**: Inadequate rest increases risk
10. **Speed Consistency**: Erratic pacing = poor control
11. **Max Heart Rate**: Consistently hitting max = overtraining

---

## 📊 EXAMPLE WEEKLY ANALYSIS

```dart
// Get this week's activities
final thisWeek = await gpsDataFetcher.getActivitiesByDateRange(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

// Calculate totals
double totalDistance = 0;
double totalDuration = 0;
double avgCadence = 0;
int activityCount = 0;

thisWeek.values.forEach((dayActivities) {
  for (var activity in dayActivities) {
    totalDistance += activity.distanceMeters / 1000; // km
    totalDuration += activity.durationSeconds / 3600; // hours
    if (activity.avgCadence != null) {
      avgCadence += activity.avgCadence!;
      activityCount++;
    }
  }
});

avgCadence = avgCadence / activityCount;

print('This Week:');
print('Distance: ${totalDistance.toStringAsFixed(1)} km');
print('Duration: ${totalDuration.toStringAsFixed(1)} hours');
print('Avg Cadence: ${avgCadence.round()} spm');
print('Rest Days: ${7 - thisWeek.length}');
```

---

## 🚀 NEXT STEPS

1. **Reload App**: Press 'R' in terminal
2. **Sync Activities**: Click "Sync Activities" button
3. **Explore Data**: Expand activities to see all metrics
4. **Check Database**: Verify data in Supabase `gps_activities` table
5. **Build Calendar View**: Use `getActivitiesByDateRange()` for calendar UI
6. **Implement AISRI**: Use complete data for injury risk calculations

---

## 📝 NOTES

- **Stride Length**: Not directly provided by Strava, we calculate it from speed and cadence
- **HR Zones**: Strava doesn't always provide - depends on watch capabilities
- **Power Data**: Only available if using a foot pod or Stryd sensor
- **Weather**: Not captured yet - available in Strava API but not implemented
- **Raw Data**: ALL original Strava data preserved in `raw_data` JSONB column

---

**Last Updated**: February 5, 2026
**Strava API Version**: v3
