# Supabase Data Object Helper - SafeStride Implementation

**Date**: February 10, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready

---

## Overview

The Supabase Data Object Helper simplifies creating and managing reactive data objects from Supabase for use in the SafeStride mobile app. It provides a clean, type-safe interface for CRUD operations, filtering, sorting, and real-time data reactivity.

---

## Features

✅ **Reactive Data Objects** - Automatically update when data changes  
✅ **CRUD Operations** - Support for Create, Read, Update, and Delete  
✅ **Advanced Filtering** - Multiple operators (equals, greater than, like, etc.)  
✅ **Sorting & Limiting** - Configure sorting direction and record limits  
✅ **Real-time Subscriptions** - Optional real-time data updates  
✅ **Global Data Store** - Access data objects from anywhere in the app  
✅ **Type Safety** - Full Dart type definitions and null safety  
✅ **Error Handling** - Comprehensive logging and error management  
✅ **Resource Management** - Proper disposal of subscriptions and streams

---

## Installation

The helper is included in the SafeStride project at:
```
lib/services/supabase_data_object_helper.dart
```

Import it in your files:
```dart
import '../services/supabase_data_object_helper.dart';
```

---

## Quick Start

### 1. Basic Usage

```dart
// Define your data object options
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
  recordLimit: 10,
  canInsert: true,
  canUpdate: true,
  canDelete: false,
);

// Create the data object
final dataObject = await createDataObject(options);

// Get data
final data = dataObject.getData();

// Listen for changes
dataObject.onDataChanged((data) {
  print('Data updated: ${data.length} records');
});
```

### 2. CRUD Operations

```dart
// Insert
await dataObject.insert({
  'user_id': userId,
  'goal_type': 'distance',
  'target_value': 100,
});

// Update
await dataObject.update(recordId, {
  'target_value': 150,
});

// Delete
await dataObject.delete(recordId);

// Refresh
await dataObject.refresh();
```

### 3. Using the Data Store

```dart
// Register a data object
final dataObject = await createDataObject(
  options,
  registerId: 'my_data_object',
);

// Access from anywhere
final obj = DataObjectStore.getDataObjectById('my_data_object');
if (obj != null) {
  final data = obj.getData();
}

// Clean up
DataObjectStore.unregister('my_data_object');
```

---

## Core Classes

### DataObjectOptions

Configuration for creating a data object.

```dart
DataObjectOptions(
  tableName: 'table_name',           // Required: Supabase table name
  fields: [DataField(...)],          // Optional: Specific fields to select
  whereClauses: [WhereClause(...)],  // Optional: Filter conditions
  sort: SortConfig(...),             // Optional: Sorting configuration
  recordLimit: 100,                  // Optional: Limit number of records
  canInsert: true,                   // Enable insert operations
  canUpdate: true,                   // Enable update operations
  canDelete: false,                  // Enable delete operations
  enableRealtime: false,             // Enable real-time subscriptions
)
```

### Field Types

```dart
enum FieldType {
  string,    // Text data
  number,    // Numeric data (int or double)
  dateTime,  // Date/timestamp data
  boolean,   // Boolean data
}
```

### Filter Operators

```dart
enum FilterOperator {
  equals,              // Exact match
  notEquals,           // Not equal to
  greaterThan,         // Greater than
  lessThan,            // Less than
  greaterThanOrEqual,  // Greater than or equal
  lessThanOrEqual,     // Less than or equal
  like,                // SQL LIKE (case-sensitive)
  ilike,               // SQL ILIKE (case-insensitive)
  isNull,              // IS NULL
  isNotNull,           // IS NOT NULL
  inList,              // IN (list)
}
```

---

## Examples

### Example 1: Athlete Profiles (Read-Only with Update)

```dart
final athleteProfilesOptions = DataObjectOptions(
  tableName: 'profiles',
  fields: [
    DataField(name: 'id', type: FieldType.string),
    DataField(name: 'email', type: FieldType.string),
    DataField(name: 'full_name', type: FieldType.string),
  ],
  whereClauses: [
    WhereClause(
      field: 'active',
      operator: FilterOperator.equals,
      value: true,
    ),
  ],
  sort: SortConfig(field: 'created_at', ascending: false),
  canUpdate: true,
);

final profiles = await createDataObject(athleteProfilesOptions);
```

### Example 2: AISRI Assessments with Real-time

```dart
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
  canInsert: true,
  canUpdate: true,
  enableRealtime: true, // ✅ Real-time updates enabled
);

final assessments = await createDataObject(
  assessmentsOptions,
  registerId: 'user_assessments',
);

// Listen for real-time updates
assessments.onDataChanged((data) {
  if (data.isNotEmpty) {
    print('Latest score: ${data.first['overall_score']}');
  }
});
```

### Example 3: Workout Calendar with Complex Filtering

```dart
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

final calendar = await createDataObject(calendarOptions);
```

### Example 4: Integration with StatefulWidget

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  SupabaseDataObject? _dataObject;
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupDataObject();
  }

  Future<void> _setupDataObject() async {
    final options = DataObjectOptions(
      tableName: 'my_table',
      canInsert: true,
      canUpdate: true,
    );

    _dataObject = await createDataObject(options);

    _dataObject!.onDataChanged((data) {
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _dataObject?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircularProgressIndicator();
    }

    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_data[index]['name']),
        );
      },
    );
  }
}
```

---

## SafeStride Integration Examples

### Kura Coach - Athlete Goals

```dart
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
    recordLimit: 1,
    canInsert: true,
    canUpdate: true,
  );

  return await createDataObject(
    options,
    registerId: 'athlete_goals_$userId',
  );
}
```

### Structured Workouts

```dart
Future<SupabaseDataObject> createStructuredWorkoutsDataObject(String userId) async {
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
  );

  return await createDataObject(options);
}
```

### Strava Activities (Read-Only with Real-time)

```dart
Future<SupabaseDataObject> createStravaActivitiesDataObject(String userId) async {
  final options = DataObjectOptions(
    tableName: 'strava_activities',
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
    enableRealtime: true,
  );

  return await createDataObject(options);
}
```

---

## Best Practices

### 1. Always Dispose Data Objects

```dart
@override
void dispose() {
  _dataObject?.dispose(); // ✅ Clean up resources
  super.dispose();
}
```

### 2. Use Data Store for Global Access

```dart
// Register in service
await createDataObject(options, registerId: 'my_data');

// Access anywhere in app
final obj = DataObjectStore.getDataObjectById('my_data');
```

### 3. Handle Loading States

```dart
bool _isLoading = true;

_dataObject!.onDataChanged((data) {
  setState(() {
    _data = data;
    _isLoading = false; // ✅ Update loading state
  });
});
```

### 4. Use Mounted Check in setState

```dart
_dataObject!.onDataChanged((data) {
  if (mounted) { // ✅ Check if widget is still mounted
    setState(() {
      _data = data;
    });
  }
});
```

### 5. Enable Real-time Only When Needed

```dart
// ✅ Use for frequently changing data
enableRealtime: true, // User's calendar, live activities

// ❌ Don't use for static reference data
enableRealtime: false, // Training zones, templates
```

### 6. Use Appropriate Permissions

```dart
// Admin panel
canInsert: true,
canUpdate: true,
canDelete: true,

// User view
canInsert: false,
canUpdate: false,
canDelete: false,

// User's own data
canInsert: true,
canUpdate: true,
canDelete: false,
```

---

## Error Handling

All operations include comprehensive error handling:

```dart
try {
  await dataObject.insert(data);
} catch (e) {
  // Error is logged automatically
  print('Operation failed: $e');
  // Show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to save data')),
  );
}
```

---

## Performance Tips

1. **Use Record Limits**: Always set `recordLimit` for large tables
2. **Select Specific Fields**: Use `fields` parameter to reduce data transfer
3. **Optimize Where Clauses**: Add indexes to filtered columns in Supabase
4. **Batch Operations**: Use Supabase RPC functions for bulk operations
5. **Dispose Unused Objects**: Clean up data objects when no longer needed

---

## Debugging

Enable logging to see data object operations:

```dart
import 'dart:developer' as developer;

// Logs are automatically generated:
// - Data object creation
// - Fetch operations
// - Insert/Update/Delete operations
// - Real-time subscriptions
// - Disposal

// View in DevTools console
```

---

## API Reference

### SupabaseDataObject

**Methods:**

- `getData()` - Get current data snapshot
- `fetch()` - Manually fetch data from Supabase
- `insert(data)` - Insert new record
- `update(id, data)` - Update existing record
- `delete(id)` - Delete record
- `refresh()` - Alias for fetch()
- `onDataChanged(callback)` - Listen for data changes
- `dispose()` - Clean up resources

**Properties:**

- `dataStream` - Stream of data changes

### DataObjectStore

**Static Methods:**

- `register(id, dataObject)` - Register data object globally
- `getDataObjectById(id)` - Get data object by ID
- `exists(id)` - Check if data object exists
- `unregister(id)` - Unregister and dispose data object
- `getAllIds()` - Get all registered IDs
- `disposeAll()` - Dispose all data objects

---

## Complete Examples

See `lib/examples/supabase_data_object_examples.dart` for comprehensive examples including:

- Basic data object creation and usage
- Advanced filtering and sorting
- CRUD operations
- Reactive data handling with StatefulWidget
- Read-only reporting scenarios
- Real-time subscription examples
- Data store usage patterns
- Kura Coach integration
- Strava activities integration

---

## Migration from Direct Supabase Calls

**Before:**
```dart
final response = await Supabase.instance.client
    .from('athlete_goals')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false)
    .limit(10);

final data = response as List<Map<String, dynamic>>;
```

**After:**
```dart
final options = DataObjectOptions(
  tableName: 'athlete_goals',
  whereClauses: [
    WhereClause(field: 'user_id', operator: FilterOperator.equals, value: userId),
  ],
  sort: SortConfig(field: 'created_at', ascending: false),
  recordLimit: 10,
);

final dataObject = await createDataObject(options);
final data = dataObject.getData();

// Plus: automatic reactivity, CRUD methods, error handling
```

---

## Support

For issues or questions:
- Check `lib/examples/supabase_data_object_examples.dart`
- Review this documentation
- Check DevTools console for logs

---

**Version History:**

- **1.0.0** (2026-02-10) - Initial release
  - Reactive data objects
  - CRUD operations
  - Advanced filtering
  - Real-time subscriptions
  - Global data store
  - Comprehensive examples
  - Full documentation

---

**Status**: ✅ Production Ready  
**Last Updated**: February 10, 2026
