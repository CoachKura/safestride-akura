import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Data Object Helper
/// Simplifies creating and managing reactive data objects from Supabase
/// with CRUD operations, filtering, sorting, and real-time reactivity

/// Field type enum
enum FieldType { string, number, dateTime, boolean }

/// Operator types for filtering
enum FilterOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  like,
  ilike,
  isNull,
  isNotNull,
  inList,
}

/// Field definition
class DataField {
  final String name;
  final FieldType type;

  const DataField({required this.name, required this.type});
}

/// Where clause for filtering
class WhereClause {
  final String field;
  final FilterOperator operator;
  final dynamic value;

  const WhereClause({
    required this.field,
    required this.operator,
    required this.value,
  });
}

/// Sort configuration
class SortConfig {
  final String field;
  final bool ascending;

  const SortConfig({required this.field, this.ascending = true});
}

/// Data object options
class DataObjectOptions {
  final String tableName;
  final List<DataField>? fields;
  final List<WhereClause>? whereClauses;
  final SortConfig? sort;
  final int? recordLimit;
  final bool canInsert;
  final bool canUpdate;
  final bool canDelete;
  final bool enableRealtime;

  const DataObjectOptions({
    required this.tableName,
    this.fields,
    this.whereClauses,
    this.sort,
    this.recordLimit,
    this.canInsert = false,
    this.canUpdate = false,
    this.canDelete = false,
    this.enableRealtime = false,
  });
}

/// Main Data Object class
class SupabaseDataObject {
  final SupabaseClient _client;
  final DataObjectOptions _options;
  List<Map<String, dynamic>> _data = [];
  final _dataController = StreamController<List<Map<String, dynamic>>>.broadcast();
  RealtimeChannel? _realtimeSubscription;
  bool _isDisposed = false;

  SupabaseDataObject(this._client, this._options) {
    if (_options.enableRealtime) {
      _setupRealtimeSubscription();
    }
  }

  /// Get current data
  List<Map<String, dynamic>> getData() => List.unmodifiable(_data);

  /// Stream of data changes
  Stream<List<Map<String, dynamic>>> get dataStream => _dataController.stream;

  /// Listen for data changes
  void onDataChanged(void Function(List<Map<String, dynamic>>) callback) {
    dataStream.listen(callback);
  }

  /// Fetch data from Supabase
  Future<List<Map<String, dynamic>>> fetch() async {
    try {
      developer.log('Fetching data from table: ${_options.tableName}');

      // Build query (use dynamic to handle type variations)
      dynamic query = _client.from(_options.tableName).select(
            _options.fields?.map((f) => f.name).join(',') ?? '*',
          );

      // Apply where clauses
      if (_options.whereClauses != null) {
        for (var clause in _options.whereClauses!) {
          query = _applyWhereClause(query, clause);
        }
      }

      // Apply sorting
      if (_options.sort != null) {
        query = query.order(
          _options.sort!.field,
          ascending: _options.sort!.ascending,
        );
      }

      // Apply limit
      if (_options.recordLimit != null) {
        query = query.limit(_options.recordLimit!);
      }

      final response = await query;
      _data = List<Map<String, dynamic>>.from(response);
      _dataController.add(_data);

      developer.log('Fetched ${_data.length} records from ${_options.tableName}');
      return _data;
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching data from ${_options.tableName}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Insert a new record
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    if (!_options.canInsert) {
      throw Exception('Insert operation not enabled for this data object');
    }

    try {
      developer.log('Inserting record into ${_options.tableName}');

      final response = await _client
          .from(_options.tableName)
          .insert(data)
          .select()
          .single();

      await fetch(); // Refresh data
      return response;
    } catch (e, stackTrace) {
      developer.log(
        'Error inserting into ${_options.tableName}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update a record
  Future<Map<String, dynamic>> update(
    dynamic id,
    Map<String, dynamic> data, {
    String idField = 'id',
  }) async {
    if (!_options.canUpdate) {
      throw Exception('Update operation not enabled for this data object');
    }

    try {
      developer.log('Updating record in ${_options.tableName} with $idField: $id');

      final response = await _client
          .from(_options.tableName)
          .update(data)
          .eq(idField, id)
          .select()
          .single();

      await fetch(); // Refresh data
      return response;
    } catch (e, stackTrace) {
      developer.log(
        'Error updating ${_options.tableName}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a record
  Future<void> delete(dynamic id, {String idField = 'id'}) async {
    if (!_options.canDelete) {
      throw Exception('Delete operation not enabled for this data object');
    }

    try {
      developer.log('Deleting record from ${_options.tableName} with $idField: $id');

      await _client.from(_options.tableName).delete().eq(idField, id);

      await fetch(); // Refresh data
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting from ${_options.tableName}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Refresh data (manual)
  Future<void> refresh() async {
    await fetch();
  }

  /// Setup realtime subscription
  void _setupRealtimeSubscription() {
    try {
      _realtimeSubscription = _client
          .channel('${_options.tableName}_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _options.tableName,
            callback: (payload) {
              developer.log('Realtime change detected in ${_options.tableName}');
              fetch(); // Refresh data on change
            },
          )
          .subscribe();

      developer.log('Realtime subscription enabled for ${_options.tableName}');
    } catch (e) {
      developer.log('Error setting up realtime subscription: $e');
    }
  }

  /// Apply where clause to query
  dynamic _applyWhereClause(
    dynamic query,
    WhereClause clause,
  ) {
    switch (clause.operator) {
      case FilterOperator.equals:
        return query.eq(clause.field, clause.value);
      case FilterOperator.notEquals:
        return query.neq(clause.field, clause.value);
      case FilterOperator.greaterThan:
        return query.gt(clause.field, clause.value);
      case FilterOperator.lessThan:
        return query.lt(clause.field, clause.value);
      case FilterOperator.greaterThanOrEqual:
        return query.gte(clause.field, clause.value);
      case FilterOperator.lessThanOrEqual:
        return query.lte(clause.field, clause.value);
      case FilterOperator.like:
        return query.like(clause.field, clause.value);
      case FilterOperator.ilike:
        return query.ilike(clause.field, clause.value);
      case FilterOperator.isNull:
        return query.isFilter(clause.field, null);
      case FilterOperator.isNotNull:
        return query.not(clause.field, 'is', null);
      case FilterOperator.inList:
        return query.inFilter(clause.field, clause.value);
    }
  }

  /// Dispose resources
  void dispose() {
    if (!_isDisposed) {
      _realtimeSubscription?.unsubscribe();
      _dataController.close();
      _isDisposed = true;
      developer.log('Data object for ${_options.tableName} disposed');
    }
  }
}

/// Data Object Store - Global registry
class DataObjectStore {
  static final Map<String, SupabaseDataObject> _store = {};

  /// Register a data object
  static void register(String id, SupabaseDataObject dataObject) {
    _store[id] = dataObject;
    developer.log('Data object registered: $id');
  }

  /// Get a data object by ID
  static SupabaseDataObject? getDataObjectById(String id) {
    return _store[id];
  }

  /// Check if data object exists
  static bool exists(String id) {
    return _store.containsKey(id);
  }

  /// Unregister a data object
  static void unregister(String id) {
    final dataObject = _store.remove(id);
    dataObject?.dispose();
    developer.log('Data object unregistered: $id');
  }

  /// Get all registered data object IDs
  static List<String> getAllIds() {
    return _store.keys.toList();
  }

  /// Dispose all data objects
  static void disposeAll() {
    for (var dataObject in _store.values) {
      dataObject.dispose();
    }
    _store.clear();
    developer.log('All data objects disposed');
  }
}

/// Factory function to create data objects
Future<SupabaseDataObject> createDataObject(
  DataObjectOptions options, {
  String? registerId,
  bool autoFetch = true,
}) async {
  final client = Supabase.instance.client;
  final dataObject = SupabaseDataObject(client, options);

  if (autoFetch) {
    await dataObject.fetch();
  }

  if (registerId != null) {
    DataObjectStore.register(registerId, dataObject);
  }

  return dataObject;
}
