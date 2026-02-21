import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_data_object_helper.dart';

/// Examples of using Supabase Data Object Helper in SafeStride

// ====================
// Example 1: Basic Data Object - Athlete Profiles
// ====================
Future<void> example1BasicUsage() async {
  // Create a data object for athlete profiles
  final athleteProfilesOptions = DataObjectOptions(
    tableName: 'profiles',
    fields: [
      DataField(name: 'id', type: FieldType.string),
      DataField(name: 'email', type: FieldType.string),
      DataField(name: 'full_name', type: FieldType.string),
      DataField(name: 'date_of_birth', type: FieldType.dateTime),
    ],
    whereClauses: [
      WhereClause(
        field: 'active',
        operator: FilterOperator.equals,
        value: true,
      ),
    ],
    sort: SortConfig(field: 'created_at', ascending: false),
    recordLimit: 100,
    canInsert: false,
    canUpdate: true,
    canDelete: false,
  );

  // Create and register the data object
  final athleteProfiles = await createDataObject(
    athleteProfilesOptions,
    registerId: 'athlete_profiles',
    autoFetch: true,
  );

  // Listen for data changes
  athleteProfiles.onDataChanged((data) {
    debugPrint('Athlete profiles updated: ${data.length} records');
  });

  // Get current data
  final profiles = athleteProfiles.getData();
  debugPrint('Current profiles: ${profiles.length}');

  // Update a profile
  await athleteProfiles.update(
    'user-id-123',
    {'full_name': 'John Updated'},
    idField: 'id',
  );

  // Manual refresh
  await athleteProfiles.refresh();
}

// ====================
// Example 2: AISRI Assessments with Real-time
// ====================
Future<void> example2AssessmentsRealtime() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;

  final assessmentsOptions = DataObjectOptions(
    tableName: 'AISRI_assessments',
    whereClauses: [
      WhereClause(
        field: 'user_id',
        operator: FilterOperator.equals,
        value: userId,
      ),
    ],
    sort: SortConfig(field: 'created_at', ascending: false),
    recordLimit: 10,
    canInsert: true,
    canUpdate: true,
    canDelete: false,
    enableRealtime: true, // Enable real-time updates
  );

  final assessments = await createDataObject(
    assessmentsOptions,
    registerId: 'user_assessments',
  );

  // Listen for updates (will fire when data changes in Supabase)
  assessments.onDataChanged((data) {
    if (data.isNotEmpty) {
      final latest = data.first;
      debugPrint('Latest assessment score: ${latest['overall_score']}');
    }
  });

  // Insert new assessment
  await assessments.insert({
    'user_id': userId,
    'overall_score': 85,
    'mobility_score': 80,
    'stability_score': 90,
    'created_at': DateTime.now().toIso8601String(),
  });
}

// ====================
// Example 3: Workout Calendar with Complex Filtering
// ====================
Future<void> example3WorkoutCalendar() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  final today = DateTime.now();
  final weekFromNow = today.add(Duration(days: 7));

  final calendarOptions = DataObjectOptions(
    tableName: 'athlete_calendar',
    whereClauses: [
      WhereClause(
        field: 'user_id',
        operator: FilterOperator.equals,
        value: userId,
      ),
      WhereClause(
        field: 'workout_date',
        operator: FilterOperator.greaterThanOrEqual,
        value: today.toIso8601String().split('T')[0],
      ),
      WhereClause(
        field: 'workout_date',
        operator: FilterOperator.lessThanOrEqual,
        value: weekFromNow.toIso8601String().split('T')[0],
      ),
      WhereClause(
        field: 'status',
        operator: FilterOperator.inList,
        value: ['scheduled', 'in_progress'],
      ),
    ],
    sort: SortConfig(field: 'workout_date', ascending: true),
    canInsert: true,
    canUpdate: true,
    canDelete: true,
  );

  final calendar = await createDataObject(
    calendarOptions,
    registerId: 'weekly_calendar',
  );

  // Get upcoming workouts
  final upcomingWorkouts = calendar.getData();
  debugPrint('Upcoming workouts: ${upcomingWorkouts.length}');

  // Complete a workout
  if (upcomingWorkouts.isNotEmpty) {
    final workoutId = upcomingWorkouts.first['id'];
    await calendar.update(workoutId, {'status': 'completed'});
  }

  // Add new workout
  await calendar.insert({
    'user_id': userId,
    'workout_date':
        today.add(Duration(days: 3)).toIso8601String().split('T')[0],
    'workout_name': 'Easy Run',
    'workout_type': 'easy_run',
    'target_distance': 5.0,
    'status': 'scheduled',
  });
}

// ====================
// Example 4: Read-only Reporting
// ====================
Future<void> example4ReadOnlyReporting() async {
  // Monthly workout summary - read-only
  final monthlySummaryOptions = DataObjectOptions(
    tableName: 'workout_summary_monthly',
    whereClauses: [
      WhereClause(
        field: 'month',
        operator: FilterOperator.equals,
        value: DateTime.now().month,
      ),
      WhereClause(
        field: 'year',
        operator: FilterOperator.equals,
        value: DateTime.now().year,
      ),
    ],
    canInsert: false,
    canUpdate: false,
    canDelete: false,
  );

  final summary = await createDataObject(
    monthlySummaryOptions,
    registerId: 'monthly_summary',
  );

  final data = summary.getData();
  if (data.isNotEmpty) {
    debugPrint('Total distance this month: ${data.first['total_distance']} km');
    debugPrint('Total workouts: ${data.first['workout_count']}');
  }
}

// ====================
// Example 5: Using Data Object Store
// ====================
Future<void> example5DataObjectStore() async {
  // Create multiple data objects
  await example1BasicUsage();
  await example2AssessmentsRealtime();
  await example3WorkoutCalendar();

  // Access from anywhere in the app
  final profiles = DataObjectStore.getDataObjectById('athlete_profiles');
  if (profiles != null) {
    debugPrint('Profiles data: ${profiles.getData().length} records');
  }

  final assessments = DataObjectStore.getDataObjectById('user_assessments');
  if (assessments != null) {
    await assessments.refresh();
  }

  // List all registered data objects
  final allIds = DataObjectStore.getAllIds();
  debugPrint('Registered data objects: $allIds');

  // Clean up specific data object
  DataObjectStore.unregister('monthly_summary');

  // Clean up all data objects (call on app shutdown)
  // DataObjectStore.disposeAll();
}

// ====================
// Example 6: Integration with StatefulWidget
// ====================
class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  SupabaseDataObject? _workoutsDataObject;
  List<Map<String, dynamic>> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupDataObject();
  }

  Future<void> _setupDataObject() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    final options = DataObjectOptions(
      tableName: 'structured_workouts',
      whereClauses: [
        WhereClause(
          field: 'created_by',
          operator: FilterOperator.equals,
          value: userId,
        ),
      ],
      sort: SortConfig(field: 'created_at', ascending: false),
      canInsert: true,
      canUpdate: true,
      canDelete: true,
      enableRealtime: true,
    );

    _workoutsDataObject = await createDataObject(options);

    // Listen for changes
    _workoutsDataObject!.onDataChanged((data) {
      if (mounted) {
        setState(() {
          _workouts = data;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _workoutsDataObject?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final workout = _workouts[index];
        return ListTile(
          title: Text(workout['name'] ?? 'Workout'),
          subtitle: Text('Distance: ${workout['total_distance']} km'),
          onTap: () => _editWorkout(workout),
        );
      },
    );
  }

  Future<void> _editWorkout(Map<String, dynamic> workout) async {
    // Update workout
    await _workoutsDataObject?.update(
      workout['id'],
      {'name': 'Updated Workout Name'},
    );
  }
}

// ====================
// Example 7: Athlete Goals Integration
// ====================
Future<SupabaseDataObject> createAthleteGoalsDataObject(String userId) async {
  final options = DataObjectOptions(
    tableName: 'athlete_goals',
    whereClauses: [
      WhereClause(
        field: 'user_id',
        operator: FilterOperator.equals,
        value: userId,
      ),
    ],
    sort: SortConfig(field: 'created_at', ascending: false),
    recordLimit: 1, // Get most recent
    canInsert: true,
    canUpdate: true,
    canDelete: false,
  );

  return await createDataObject(
    options,
    registerId: 'athlete_goals_$userId',
  );
}

// ====================
// Example 8: Strava Activities
// ====================
Future<SupabaseDataObject> createStravaActivitiesDataObject(
    String userId) async {
  final options = DataObjectOptions(
    tableName: 'strava_activities',
    fields: [
      DataField(name: 'id', type: FieldType.number),
      DataField(name: 'name', type: FieldType.string),
      DataField(name: 'distance', type: FieldType.number),
      DataField(name: 'moving_time', type: FieldType.number),
      DataField(name: 'start_date', type: FieldType.dateTime),
    ],
    whereClauses: [
      WhereClause(
        field: 'user_id',
        operator: FilterOperator.equals,
        value: userId,
      ),
      WhereClause(
        field: 'type',
        operator: FilterOperator.equals,
        value: 'Run',
      ),
    ],
    sort: SortConfig(field: 'start_date', ascending: false),
    recordLimit: 50,
    canInsert: false,
    canUpdate: false,
    canDelete: false,
    enableRealtime: true,
  );

  return await createDataObject(
    options,
    registerId: 'strava_activities_$userId',
  );
}
