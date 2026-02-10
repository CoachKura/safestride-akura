import 'package:flutter/material.dart';
import '../services/supabase_data_object_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Example of using Supabase Data Object Helper in Assessment Results Screen
/// This demonstrates how to integrate reactive data objects into existing screens

class AssessmentResultsDataService {
  static SupabaseDataObject? _assessmentsDataObject;
  static SupabaseDataObject? _protocolDataObject;

  /// Create data object for user's assessments with real-time updates
  static Future<SupabaseDataObject> createAssessmentsDataObject(
    String userId,
  ) async {
    final options = DataObjectOptions(
      tableName: 'aisri_assessments',
      fields: [
        DataField(name: 'id', type: FieldType.string),
        DataField(name: 'overall_score', type: FieldType.number),
        DataField(name: 'mobility_score', type: FieldType.number),
        DataField(name: 'stability_score', type: FieldType.number),
        DataField(name: 'strength_score', type: FieldType.number),
        DataField(name: 'power_score', type: FieldType.number),
        DataField(name: 'endurance_score', type: FieldType.number),
        DataField(name: 'created_at', type: FieldType.dateTime),
      ],
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
      canUpdate: false,
      canDelete: false,
      enableRealtime: true, // ✅ Real-time updates for new assessments
    );

    _assessmentsDataObject = await createDataObject(
      options,
      registerId: 'user_assessments_$userId',
    );

    return _assessmentsDataObject!;
  }

  /// Create data object for training protocol status
  static Future<SupabaseDataObject> createProtocolDataObject(
    String userId,
  ) async {
    final options = DataObjectOptions(
      tableName: 'athlete_goals',
      whereClauses: [
        WhereClause(
          field: 'user_id',
          operator: FilterOperator.equals,
          value: userId,
        ),
        WhereClause(
          field: 'generated_from_evaluation',
          operator: FilterOperator.equals,
          value: true,
        ),
      ],
      sort: SortConfig(field: 'created_at', ascending: false),
      recordLimit: 1,
      canInsert: true,
      canUpdate: true,
      canDelete: false,
    );

    _protocolDataObject = await createDataObject(
      options,
      registerId: 'training_protocol_$userId',
    );

    return _protocolDataObject!;
  }

  /// Check if user has an active training protocol
  static Future<bool> hasActiveProtocol(String userId) async {
    if (_protocolDataObject == null) {
      await createProtocolDataObject(userId);
    }

    await _protocolDataObject!.refresh();
    final data = _protocolDataObject!.getData();

    return data.isNotEmpty;
  }

  /// Get latest assessment data
  static Future<Map<String, dynamic>?> getLatestAssessment(String userId) async {
    if (_assessmentsDataObject == null) {
      await createAssessmentsDataObject(userId);
    }

    await _assessmentsDataObject!.refresh();
    final data = _assessmentsDataObject!.getData();

    return data.isNotEmpty ? data.first : null;
  }

  /// Clean up data objects
  static void dispose() {
    _assessmentsDataObject?.dispose();
    _protocolDataObject?.dispose();
    _assessmentsDataObject = null;
    _protocolDataObject = null;
  }
}

/// Example: Enhanced Assessment Results Screen with Data Object Integration
/// This shows how to use data objects in a StatefulWidget

mixin AssessmentResultsDataMixin<T extends StatefulWidget> on State<T> {
  SupabaseDataObject? _assessmentsDataObject;
  SupabaseDataObject? _calendarDataObject;
  List<Map<String, dynamic>> _recentAssessments = [];
  List<Map<String, dynamic>> _upcomingWorkouts = [];

  Future<void> setupAssessmentDataObjects() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Setup assessments data object with real-time
    _assessmentsDataObject = await AssessmentResultsDataService
        .createAssessmentsDataObject(userId);

    // Listen for new assessments
    _assessmentsDataObject!.onDataChanged((data) {
      if (mounted) {
        setState(() {
          _recentAssessments = data;
        });
      }
    });

    // Setup calendar data object
    final today = DateTime.now();
    final twoWeeksFromNow = today.add(Duration(days: 14));

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
          value: twoWeeksFromNow.toIso8601String().split('T')[0],
        ),
        WhereClause(
          field: 'status',
          operator: FilterOperator.equals,
          value: 'scheduled',
        ),
      ],
      sort: SortConfig(field: 'workout_date', ascending: true),
      recordLimit: 10,
      canUpdate: true,
    );

    _calendarDataObject = await createDataObject(calendarOptions);

    // Listen for workout updates
    _calendarDataObject!.onDataChanged((data) {
      if (mounted) {
        setState(() {
          _upcomingWorkouts = data;
        });
      }
    });
  }

  void disposeAssessmentDataObjects() {
    _assessmentsDataObject?.dispose();
    _calendarDataObject?.dispose();
  }

  // Getters for use in build method
  List<Map<String, dynamic>> get recentAssessments => _recentAssessments;
  List<Map<String, dynamic>> get upcomingWorkouts => _upcomingWorkouts;
}

/// Example: Protocol Status Card Widget
class ProtocolStatusCard extends StatefulWidget {
  final String userId;

  const ProtocolStatusCard({super.key, required this.userId});

  @override
  State<ProtocolStatusCard> createState() => _ProtocolStatusCardState();
}

class _ProtocolStatusCardState extends State<ProtocolStatusCard> {
  SupabaseDataObject? _protocolDataObject;
  Map<String, dynamic>? _protocolData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupProtocolDataObject();
  }

  Future<void> _setupProtocolDataObject() async {
    _protocolDataObject = await AssessmentResultsDataService
        .createProtocolDataObject(widget.userId);

    _protocolDataObject!.onDataChanged((data) {
      if (mounted) {
        setState(() {
          _protocolData = data.isNotEmpty ? data.first : null;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Data object is managed by service, don't dispose here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_protocolData == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No active training protocol'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Training Protocol',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Fitness Level: ${_protocolData!['fitness_level']}'),
            Text('Weekly Frequency: ${_protocolData!['recommended_weekly_frequency']} days'),
            Text('Weekly Volume: ${_protocolData!['recommended_weekly_volume']} km'),
            Text('Duration: ${_protocolData!['protocol_duration_weeks']} weeks'),
          ],
        ),
      ),
    );
  }
}

/// Example: Assessment History List with Real-time Updates
class AssessmentHistoryList extends StatefulWidget {
  final String userId;

  const AssessmentHistoryList({super.key, required this.userId});

  @override
  State<AssessmentHistoryList> createState() => _AssessmentHistoryListState();
}

class _AssessmentHistoryListState extends State<AssessmentHistoryList> {
  SupabaseDataObject? _assessmentsDataObject;
  List<Map<String, dynamic>> _assessments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupDataObject();
  }

  Future<void> _setupDataObject() async {
    final options = DataObjectOptions(
      tableName: 'aisri_assessments',
      whereClauses: [
        WhereClause(
          field: 'user_id',
          operator: FilterOperator.equals,
          value: widget.userId,
        ),
      ],
      sort: SortConfig(field: 'created_at', ascending: false),
      recordLimit: 20,
      enableRealtime: true, // ✅ Real-time updates
    );

    _assessmentsDataObject = await createDataObject(options);

    // Listen for changes (new assessments added automatically)
    _assessmentsDataObject!.onDataChanged((data) {
      if (mounted) {
        setState(() {
          _assessments = data;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _assessmentsDataObject?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _assessments.length,
      itemBuilder: (context, index) {
        final assessment = _assessments[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${assessment['overall_score']}'),
          ),
          title: Text('AISRI Score: ${assessment['overall_score']}'),
          subtitle: Text(
            'Date: ${DateTime.parse(assessment['created_at']).toString().split(' ')[0]}',
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to assessment details
          },
        );
      },
    );
  }
}
