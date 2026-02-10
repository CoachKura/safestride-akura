import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';

/// Service for connecting and syncing data with Garmin wearable devices
/// Supports: Forerunner, Fenix, Vivoactive, Venu series
class GarminConnectService {
  static const MethodChannel _channel = MethodChannel('com.safestride/garmin');
  static const EventChannel _eventChannel = EventChannel('com.safestride/garmin_events');
  
  // TEST_MODE: Set to true for testing without native implementation
  // Set to false to use actual Garmin device connection via native code
  static const bool TEST_MODE = false;
  
  // Device connection state
  static bool _isConnected = false;
  static String? _connectedDeviceId;
  static String? _connectedDeviceName;
  static Map<String, dynamic>? _deviceInfo;
  
  // Real-time workout data stream
  static StreamSubscription? _dataSubscription;
  static final StreamController<Map<String, dynamic>> _workoutDataController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Getters
  static bool get isConnected => _isConnected;
  static String? get connectedDeviceId => _connectedDeviceId;
  static String? get connectedDeviceName => _connectedDeviceName;
  static Map<String, dynamic>? get deviceInfo => _deviceInfo;
  static Stream<Map<String, dynamic>> get workoutDataStream => _workoutDataController.stream;

  /// Initialize Garmin SDK
  static Future<bool> initialize() async {
    try {
      final result = await _channel.invokeMethod('initialize');
      
      // Start listening to device events
      _dataSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
        _handleDeviceEvent(event);
      });
      
      return result == true;
    } catch (e) {
      print('Error initializing Garmin SDK: $e');
      return false;
    }
  }

  /// Scan for nearby Garmin devices
  /// connectionType: 'bluetooth', 'wifi', or 'both'
  static Future<List<Map<String, dynamic>>> scanForDevices({
    int durationSeconds = 10,
    String connectionType = 'both',
  }) async {
    try {
      final result = await _channel.invokeMethod('scanDevices', {
        'duration': durationSeconds,
        'connectionType': connectionType,
      });
      
      if (result is List) {
        return result.map((device) => Map<String, dynamic>.from(device)).toList();
      }
      return [];
    } catch (e) {
      print('Error scanning for devices: $e');
      
      // TEST MODE: Return mock devices if native implementation not ready
      if (TEST_MODE) {
        await Future.delayed(Duration(seconds: 2)); // Simulate scanning
        return _getMockDevices(connectionType);
      }
      
      return [];
    }
  }

  /// Mock devices for testing UI (remove once native implementation complete)
  static List<Map<String, dynamic>> _getMockDevices(String connectionType) {
    final mockDevices = <Map<String, dynamic>>[];
    
    if (connectionType == 'bluetooth' || connectionType == 'both') {
      mockDevices.add({
        'id': 'mock-bt-001',
        'name': 'Forerunner 265 (Test)',
        'connection_type': 'bluetooth',
        'signal_strength': 85,
      });
    }
    
    if (connectionType == 'wifi' || connectionType == 'both') {
      mockDevices.add({
        'id': 'mock-wifi-001',
        'name': 'Forerunner 265 WiFi (Test)',
        'connection_type': 'wifi',
        'ip_address': '192.168.1.100',
        'signal_strength': 90,
      });
    }
    
    return mockDevices;
  }

  /// Scan for Garmin devices on local WiFi network
  static Future<List<Map<String, dynamic>>> scanWiFiDevices({int durationSeconds = 10}) async {
    try {
      final result = await _channel.invokeMethod('scanWiFiDevices', {
        'duration': durationSeconds,
      });
      
      if (result is List) {
        return result.map((device) => Map<String, dynamic>.from(device)).toList();
      }
      return [];
    } catch (e) {
      print('Error scanning WiFi devices: $e');
      
      // TEST MODE: Return mock WiFi devices
      if (TEST_MODE) {
        await Future.delayed(Duration(seconds: 2));
        return _getMockDevices('wifi');
      }
      
      return [];
    }
  }

  /// Scan for Garmin devices via Bluetooth
  static Future<List<Map<String, dynamic>>> scanBluetoothDevices({int durationSeconds = 10}) async {
    try {
      final result = await _channel.invokeMethod('scanBluetoothDevices', {
        'duration': durationSeconds,
      });
      
      if (result is List) {
        return result.map((device) => Map<String, dynamic>.from(device)).toList();
      }
      return [];
    } catch (e) {
      print('Error scanning Bluetooth devices: $e');
      
      // TEST MODE: Return mock Bluetooth devices
      if (TEST_MODE) {
        await Future.delayed(Duration(seconds: 2));
        return _getMockDevices('bluetooth');
      }
      
      return [];
    }
  }

  /// Connect to a Garmin device
  /// connectionType: 'bluetooth' or 'wifi'
  /// ipAddress: required if connectionType is 'wifi'
  static Future<bool> connectToDevice(
    String deviceId, {
    String connectionType = 'bluetooth',
    String? ipAddress,
  }) async {
    try {
      final params = {
        'deviceId': deviceId,
        'connectionType': connectionType,
      };
      
      if (connectionType == 'wifi' && ipAddress != null) {
        params['ipAddress'] = ipAddress;
      }
      
      final result = await _channel.invokeMethod('connectDevice', params);
      
      if (result == true) {
        _isConnected = true;
        _connectedDeviceId = deviceId;
        
        // Get device info
        _deviceInfo = await getDeviceInfo();
        _connectedDeviceName = _deviceInfo?['name'] ?? 'Garmin Device';
        _deviceInfo?['connectionType'] = connectionType;
        _deviceInfo?['ipAddress'] = ipAddress;
        
        // Save connection to database
        await _saveDeviceConnection();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error connecting to device: $e');
      
      // TEST MODE: Simulate successful connection
      if (TEST_MODE) {
        await Future.delayed(Duration(seconds: 1));
        _isConnected = true;
        _connectedDeviceId = deviceId;
        _connectedDeviceName = 'Forerunner 265 (Test Mode)';
        _deviceInfo = {
          'name': 'Forerunner 265 (Test Mode)',
          'model': 'Forerunner 265',
          'firmware': '4.50 (Test)',
          'battery': 85,
          'connectionType': connectionType,
          'ipAddress': ipAddress,
        };
        
        // Save connection to database
        await _saveDeviceConnection();
        
        return true;
      }
      
      return false;
    }
  }

  /// Disconnect from current device
  static Future<bool> disconnect() async {
    try {
      final result = await _channel.invokeMethod('disconnect');
      
      _isConnected = false;
      _connectedDeviceId = null;
      _connectedDeviceName = null;
      _deviceInfo = null;
      
      return result == true;
    } catch (e) {
      print('Error disconnecting: $e');
      if (TEST_MODE) {
        _isConnected = false;
        _connectedDeviceId = null;
        _connectedDeviceName = null;
        _deviceInfo = null;
        return true;
      }
      return false;
    }
  }

  /// Get device information (battery, firmware, capabilities)
  static Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod('getDeviceInfo');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      print('Error getting device info: $e');
      if (TEST_MODE) {
        // Return mock device info
        return _deviceInfo;
      }
      return null;
    }
  }

  /// Start workout tracking on Garmin device
  static Future<bool> startWorkout({
    required String workoutType, // 'running', 'cycling', 'walking', 'strength'
    String? targetHrZone,
    double? targetPace,
    double? targetDistance,
  }) async {
    try {
      final result = await _channel.invokeMethod('startWorkout', {
        'workoutType': workoutType,
        'targetHrZone': targetHrZone,
        'targetPace': targetPace,
        'targetDistance': targetDistance,
      });
      
      return result == true;
    } catch (e) {
      print('Error starting workout: $e');
      return false;
    }
  }

  /// Stop workout tracking
  static Future<Map<String, dynamic>?> stopWorkout() async {
    try {
      final result = await _channel.invokeMethod('stopWorkout');
      
      if (result != null) {
        final workoutData = Map<String, dynamic>.from(result);
        
        // Save to database
        await _saveWorkoutData(workoutData);
        
        return workoutData;
      }
      return null;
    } catch (e) {
      print('Error stopping workout: $e');
      return null;
    }
  }

  /// Pause workout
  static Future<bool> pauseWorkout() async {
    try {
      final result = await _channel.invokeMethod('pauseWorkout');
      return result == true;
    } catch (e) {
      print('Error pausing workout: $e');
      return false;
    }
  }

  /// Resume workout
  static Future<bool> resumeWorkout() async {
    try {
      final result = await _channel.invokeMethod('resumeWorkout');
      return result == true;
    } catch (e) {
      print('Error resuming workout: $e');
      return false;
    }
  }

  /// Get real-time heart rate
  static Future<int?> getCurrentHeartRate() async {
    try {
      final result = await _channel.invokeMethod('getCurrentHeartRate');
      return result as int?;
    } catch (e) {
      print('Error getting heart rate: $e');
      return null;
    }
  }

  /// Sync historical data from device
  static Future<List<Map<String, dynamic>>> syncHistoricalData({int days = 7}) async {
    try {
      final result = await _channel.invokeMethod('syncHistoricalData', {
        'days': days,
      });
      
      if (result is List) {
        final workouts = result.map((w) => Map<String, dynamic>.from(w)).toList();
        
        // Save each workout to database
        for (var workout in workouts) {
          await _saveWorkoutData(workout);
        }
        
        return workouts;
      }
      return [];
    } catch (e) {
      print('Error syncing historical data: $e');
      return [];
    }
  }

  /// Send workout plan to Garmin device  
  static Future<bool> sendWorkoutToDevice(Map<String, dynamic> workout) async {
    try {
      final result = await _channel.invokeMethod('sendWorkout', {
        'workout': jsonEncode(workout),
      });
      
      return result == true;
    } catch (e) {
      print('Error sending workout to device: $e');
      return false;
    }
  }

  /// Get device battery level
  static Future<int?> getBatteryLevel() async {
    try {
      final result = await _channel.invokeMethod('getBatteryLevel');
      return result as int?;
    } catch (e) {
      print('Error getting battery level: $e');
      if (TEST_MODE) {
        // Return 85% battery for test mode
        return 85;
      }
      return null;
    }
  }

  /// Set target HR zones on device
  static Future<bool> setHeartRateZones(Map<String, int> zones) async {
    try {
      final result = await _channel.invokeMethod('setHeartRateZones', {
        'zones': zones,
      });
      
      return result == true;
    } catch (e) {
      print('Error setting HR zones: $e');
      return false;
    }
  }

  /// Enable live tracking (share location during workout)
  static Future<bool> enableLiveTracking(bool enable) async {
    try {
      final result = await _channel.invokeMethod('enableLiveTracking', {
        'enable': enable,
      });
      
      return result == true;
    } catch (e) {
      print('Error toggling live tracking: $e');
      return false;
    }
  }

  /// Handle device events (real-time data)
  static void _handleDeviceEvent(dynamic event) {
    try {
      final data = Map<String, dynamic>.from(event);
      final eventType = data['type'] as String?;
      
      switch (eventType) {
        case 'heart_rate':
          _workoutDataController.add({
            'type': 'heart_rate',
            'value': data['value'],
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
          
        case 'location':
          _workoutDataController.add({
            'type': 'location',
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'altitude': data['altitude'],
            'speed': data['speed'],
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
          
        case 'workout_update':
          _workoutDataController.add({
            'type': 'workout_update',
            'distance': data['distance'],
            'duration': data['duration'],
            'pace': data['pace'],
            'calories': data['calories'],
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
          
        case 'device_disconnected':
          _isConnected = false;
          _connectedDeviceId = null;
          _workoutDataController.add({
            'type': 'device_disconnected',
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
      }
    } catch (e) {
      print('Error handling device event: $e');
    }
  }

  /// Save device connection to database
  static Future<void> _saveDeviceConnection() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      await Supabase.instance.client.from('garmin_devices').upsert({
        'user_id': userId,
        'device_id': _connectedDeviceId,
        'device_name': _connectedDeviceName,
        'connection_type': _deviceInfo?['connectionType'] ?? 'bluetooth',
        'ip_address': _deviceInfo?['ipAddress'],
        'device_info': _deviceInfo,
        'last_connected_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });
    } catch (e) {
      print('Error saving device connection: $e');
    }
  }

  /// Save workout data to database
  static Future<void> _saveWorkoutData(Map<String, dynamic> workoutData) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      await Supabase.instance.client.from('gps_activities').insert({
        'user_id': userId,
        'device_source': 'garmin',
        'device_id': _connectedDeviceId,
        'activity_type': workoutData['workout_type'] ?? 'running',
        'start_time': workoutData['start_time'] ?? DateTime.now().toIso8601String(),
        'duration_seconds': workoutData['duration_seconds'] ?? 0,
        'distance_meters': workoutData['distance_meters'] ?? 0,
        'avg_heart_rate': workoutData['avg_heart_rate'],
        'max_heart_rate': workoutData['max_heart_rate'],
        'avg_pace': workoutData['avg_pace'],
        'calories_burned': workoutData['calories_burned'],
        'elevation_gain': workoutData['elevation_gain'],
        'avg_cadence': workoutData['avg_cadence'],
        'track_points': workoutData['track_points'] ?? [],
      });
    } catch (e) {
      print('Error saving workout data: $e');
    }
  }

  /// Get connected device status
  static Future<Map<String, dynamic>> getDeviceStatus() async {
    if (!_isConnected) {
      return {
        'connected': false,
        'message': 'No device connected',
      };
    }
    
    try {
      final battery = await getBatteryLevel();
      final info = await getDeviceInfo();
      
      return {
        'connected': true,
        'device_id': _connectedDeviceId,
        'device_name': _connectedDeviceName,
        'battery_level': battery,
        'device_info': info,
      };
    } catch (e) {
      return {
        'connected': true,
        'error': e.toString(),
      };
    }
  }

  /// Dispose resources
  static void dispose() {
    _dataSubscription?.cancel();
    _workoutDataController.close();
  }
}
