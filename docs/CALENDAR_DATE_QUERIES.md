# Calendar Date-Wise Data Query Guide

## 📅 How to Query Strava Data by Calendar Dates

This guide shows practical examples for querying activities organized by calendar dates for AISRI injury risk analysis.

---

## 🎯 BASIC CALENDAR QUERIES

### 1. Get Activities for Current Week

```dart
import 'package:akura_mobile/services/gps_data_fetcher.dart';

// Calculate start of current week (Monday)
DateTime getStartOfWeek() {
  final now = DateTime.now();
  final daysFromMonday = now.weekday - 1;
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromMonday));
}

// Get this week's activities
final startOfWeek = getStartOfWeek();
final endOfWeek = startOfWeek.add(Duration(days: 6));

final activities = await _gpsDataFetcher.getActivitiesByDateRange(
  startDate: startOfWeek,
  endDate: endOfWeek,
);

// Result: Map<DateTime, List<GPSActivity>>
// Each date has list of activities for that day
```

### 2. Get Activities for Current Month

```dart
// Get this month's activities
final now = DateTime.now();
final startOfMonth = DateTime(now.year, now.month, 1);
final endOfMonth = DateTime(now.year, now.month + 1, 0); // Last day of month

final activities = await _gpsDataFetcher.getActivitiesByDateRange(
  startDate: startOfMonth,
  endDate: endOfMonth,
);

print('Total days with activities: ${activities.length}');
```

### 3. Get Activities for Last 30 Days

```dart
final endDate = DateTime.now();
final startDate = endDate.subtract(Duration(days: 30));

final activities = await _gpsDataFetcher.getActivitiesByDateRange(
  startDate: startDate,
  endDate: endDate,
);
```

### 4. Get Activities for Specific Date

```dart
// Get all runs on December 25, 2024
final specificDate = DateTime(2024, 12, 25);
final nextDay = specificDate.add(Duration(days: 1));

final activities = await _gpsDataFetcher.getActivitiesByDateRange(
  startDate: specificDate,
  endDate: nextDay,
);

// Check if there were activities on that date
if (activities.containsKey(specificDate)) {
  print('Activities on ${specificDate.toString().split(' ')[0]}:');
  for (var activity in activities[specificDate]!) {
    print('  - ${(activity.distanceMeters / 1000).toStringAsFixed(2)} km');
  }
} else {
  print('No activities on that date (rest day)');
}
```

---

## 📊 CALENDAR ANALYTICS

### Weekly Training Load Analysis

```dart
class WeeklyTrainingLoad {
  final DateTime weekStart;
  double totalDistance = 0; // km
  double totalDuration = 0; // hours
  int totalActivities = 0;
  int restDays = 0;
  double avgCadence = 0;
  double avgHeartRate = 0;
  double totalElevationGain = 0; // meters
  
  WeeklyTrainingLoad(this.weekStart);
}

// Calculate weekly training load
Future<WeeklyTrainingLoad> calculateWeeklyLoad(DateTime weekStart) async {
  final weekEnd = weekStart.add(Duration(days: 6));
  final activities = await _gpsDataFetcher.getActivitiesByDateRange(
    startDate: weekStart,
    endDate: weekEnd,
  );
  
  final load = WeeklyTrainingLoad(weekStart);
  load.restDays = 7 - activities.length;
  
  int cadenceCount = 0;
  int hrCount = 0;
  
  activities.values.forEach((dayActivities) {
    for (var activity in dayActivities) {
      load.totalDistance += activity.distanceMeters / 1000;
      load.totalDuration += activity.durationSeconds / 3600;
      load.totalActivities++;
      
      if (activity.avgCadence != null) {
        load.avgCadence += activity.avgCadence!;
        cadenceCount++;
      }
      
      if (activity.avgHeartRate != null) {
        load.avgHeartRate += activity.avgHeartRate!;
        hrCount++;
      }
      
      if (activity.elevationGain != null) {
        load.totalElevationGain += activity.elevationGain!;
      }
    }
  });
  
  if (cadenceCount > 0) load.avgCadence /= cadenceCount;
  if (hrCount > 0) load.avgHeartRate /= hrCount;
  
  return load;
}

// Usage
final thisWeekLoad = await calculateWeeklyLoad(getStartOfWeek());
print('This Week Summary:');
print('Distance: ${thisWeekLoad.totalDistance.toStringAsFixed(1)} km');
print('Duration: ${thisWeekLoad.totalDuration.toStringAsFixed(1)} hours');
print('Activities: ${thisWeekLoad.totalActivities}');
print('Rest Days: ${thisWeekLoad.restDays}');
print('Avg Cadence: ${thisWeekLoad.avgCadence.round()} spm');
```

### Monthly Distance Trend

```dart
// Get distance for each month in 2024
Future<Map<int, double>> getMonthlyDistances(int year) async {
  Map<int, double> monthlyDistances = {};
  
  for (int month = 1; month <= 12; month++) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);
    
    final activities = await _gpsDataFetcher.getActivitiesByDateRange(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
    
    double totalDistance = 0;
    activities.values.forEach((dayActivities) {
      for (var activity in dayActivities) {
        totalDistance += activity.distanceMeters / 1000;
      }
    });
    
    monthlyDistances[month] = totalDistance;
  }
  
  return monthlyDistances;
}

// Usage
final distances2024 = await getMonthlyDistances(2024);
distances2024.forEach((month, distance) {
  print('Month $month: ${distance.toStringAsFixed(1)} km');
});
```

### Identify Rest Days

```dart
// Get all dates with activities in a date range
Future<Set<DateTime>> getDatesWithActivities(
  DateTime startDate, 
  DateTime endDate
) async {
  final activities = await _gpsDataFetcher.getActivitiesByDateRange(
    startDate: startDate,
    endDate: endDate,
  );
  
  return activities.keys.toSet();
}

// Find rest days
Future<List<DateTime>> getRestDays(DateTime startDate, DateTime endDate) async {
  final activeDates = await getDatesWithActivities(startDate, endDate);
  final restDays = <DateTime>[];
  
  DateTime current = startDate;
  while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
    final dateOnly = DateTime(current.year, current.month, current.day);
    if (!activeDates.contains(dateOnly)) {
      restDays.add(dateOnly);
    }
    current = current.add(Duration(days: 1));
  }
  
  return restDays;
}

// Usage
final restDays = await getRestDays(
  DateTime.now().subtract(Duration(days: 30)),
  DateTime.now(),
);
print('Rest days in last 30 days: ${restDays.length}');
```

---

## 🚨 AISRI INJURY RISK CALCULATIONS

### Acute:Chronic Workload Ratio (ACWR)

```dart
// Calculate ACWR for injury risk assessment
// Safe range: 0.8 - 1.3
// Caution: 1.3 - 1.5
// Danger: > 1.5

Future<double> calculateACWR() async {
  final now = DateTime.now();
  
  // Acute load: Last 7 days
  final acuteStart = now.subtract(Duration(days: 7));
  final acuteLoad = await calculateWeeklyLoad(acuteStart);
  
  // Chronic load: Average of last 4 weeks
  double chronicDistance = 0;
  
  for (int i = 1; i <= 4; i++) {
    final weekStart = now.subtract(Duration(days: 7 * (i + 1)));
    final weekLoad = await calculateWeeklyLoad(weekStart);
    chronicDistance += weekLoad.totalDistance;
  }
  
  final chronicAvg = chronicDistance / 4;
  
  // Calculate ratio
  final acwr = acuteLoad.totalDistance / chronicAvg;
  
  print('Acute Load (7 days): ${acuteLoad.totalDistance.toStringAsFixed(1)} km');
  print('Chronic Load (4-week avg): ${chronicAvg.toStringAsFixed(1)} km');
  print('ACWR: ${acwr.toStringAsFixed(2)}');
  
  if (acwr > 1.5) {
    print('⚠️ DANGER: High injury risk!');
  } else if (acwr > 1.3) {
    print('⚠️ CAUTION: Moderate injury risk');
  } else {
    print('✅ SAFE: Low injury risk');
  }
  
  return acwr;
}
```

### Weekly Cadence Tracking

```dart
// Track cadence trend over multiple weeks
Future<List<Map<String, dynamic>>> getCadenceTrend(int weeks) async {
  final trends = <Map<String, dynamic>>[];
  final now = DateTime.now();
  
  for (int i = 0; i < weeks; i++) {
    final weekStart = now.subtract(Duration(days: 7 * (i + 1)));
    final weekEnd = weekStart.add(Duration(days: 6));
    
    final activities = await _gpsDataFetcher.getActivitiesByDateRange(
      startDate: weekStart,
      endDate: weekEnd,
    );
    
    double totalCadence = 0;
    int count = 0;
    
    activities.values.forEach((dayActivities) {
      for (var activity in dayActivities) {
        if (activity.avgCadence != null) {
          totalCadence += activity.avgCadence!;
          count++;
        }
      }
    });
    
    final avgCadence = count > 0 ? totalCadence / count : 0;
    
    trends.add({
      'week': i + 1,
      'weekStart': weekStart,
      'avgCadence': avgCadence,
      'activities': count,
    });
  }
  
  return trends.reversed.toList(); // Oldest to newest
}

// Usage
final cadenceTrend = await getCadenceTrend(12); // Last 12 weeks
print('Cadence Trend (last 12 weeks):');
for (var week in cadenceTrend) {
  print('Week ${week['week']}: ${week['avgCadence'].round()} spm');
}
```

### Heart Rate Zone Distribution

```dart
// Analyze time spent in each HR zone
Future<Map<String, double>> getHRZoneDistribution(
  DateTime startDate, 
  DateTime endDate
) async {
  final activities = await _gpsDataFetcher.getActivitiesByDateRange(
    startDate: startDate,
    endDate: endDate,
  );
  
  int zone1 = 0, zone2 = 0, zone3 = 0, zone4 = 0, zone5 = 0;
  
  activities.values.forEach((dayActivities) {
    for (var activity in dayActivities) {
      zone1 += activity.hrZone1Seconds ?? 0;
      zone2 += activity.hrZone2Seconds ?? 0;
      zone3 += activity.hrZone3Seconds ?? 0;
      zone4 += activity.hrZone4Seconds ?? 0;
      zone5 += activity.hrZone5Seconds ?? 0;
    }
  });
  
  final total = zone1 + zone2 + zone3 + zone4 + zone5;
  
  return {
    'Zone 1 (Recovery)': total > 0 ? zone1 / total * 100 : 0,
    'Zone 2 (Aerobic)': total > 0 ? zone2 / total * 100 : 0,
    'Zone 3 (Tempo)': total > 0 ? zone3 / total * 100 : 0,
    'Zone 4 (Threshold)': total > 0 ? zone4 / total * 100 : 0,
    'Zone 5 (Anaerobic)': total > 0 ? zone5 / total * 100 : 0,
  };
}

// Usage
final distribution = await getHRZoneDistribution(
  DateTime.now().subtract(Duration(days: 30)),
  DateTime.now(),
);

print('HR Zone Distribution (last 30 days):');
distribution.forEach((zone, percentage) {
  print('$zone: ${percentage.toStringAsFixed(1)}%');
});
```

---

## 📅 CALENDAR UI IMPLEMENTATION

### Build Calendar with Activity Indicators

```dart
import 'package:table_calendar/table_calendar.dart';

class ActivityCalendar extends StatefulWidget {
  @override
  _ActivityCalendarState createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends State<ActivityCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<GPSActivity>> _activities = {};
  
  @override
  void initState() {
    super.initState();
    _loadMonthActivities();
  }
  
  Future<void> _loadMonthActivities() async {
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    final activities = await _gpsDataFetcher.getActivitiesByDateRange(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
    
    setState(() {
      _activities = activities;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime.now(),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        final dateOnly = DateTime(day.year, day.month, day.day);
        return _activities[dateOnly] ?? [];
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _showActivitiesForDay(selectedDay);
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        _loadMonthActivities();
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
  
  void _showActivitiesForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final activities = _activities[dateOnly];
    
    if (activities == null || activities.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Rest Day'),
          content: Text('No activities on ${day.toString().split(' ')[0]}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activities on ${day.toString().split(' ')[0]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: activities.map((activity) => ListTile(
            leading: Icon(Icons.directions_run),
            title: Text('${(activity.distanceMeters / 1000).toStringAsFixed(2)} km'),
            subtitle: Text('${(activity.durationSeconds / 60).round()} min'),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
```

---

## 💡 TIPS & BEST PRACTICES

### Query Performance
- **Use Indexes**: The `start_time` column is indexed for fast queries
- **Limit Date Ranges**: Query smaller ranges (weeks/months) instead of entire history
- **Cache Results**: Store frequently accessed data in memory

### Data Consistency
- **Normalize Dates**: Always use `DateTime(year, month, day)` to remove time component
- **Handle Timezones**: Activities stored in UTC, convert to local for display
- **Check Nulls**: Not all watches provide all metrics (HR zones, power, etc.)

### Error Handling
```dart
try {
  final activities = await _gpsDataFetcher.getActivitiesByDateRange(
    startDate: startDate,
    endDate: endDate,
  );
  // Process activities
} catch (e) {
  print('Error loading activities: $e');
  // Show error to user
}
```

---

## 🚀 NEXT STEPS

1. **Implement Weekly Summary**: Show user's training load for current week
2. **Add Calendar View**: Visual calendar with activity indicators
3. **Create Trends Dashboard**: Charts showing distance, cadence, HR trends
4. **Build ACWR Calculator**: Real-time injury risk assessment
5. **Add Rest Day Recommendations**: Based on training load

---

**Last Updated**: February 5, 2026
