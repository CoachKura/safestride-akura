// Device Integration Service
// Manages connections to multiple fitness platforms
// Supports: Strava, Garmin, Polar, Suunto, COROS, Fitbit, Whoop

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

enum DevicePlatform {
  strava,
  garmin,
  polar,
  suunto,
  coros,
  fitbit,
  whoop,
  manual, // For file uploads
}

class DeviceConnection {
  final String id;
  final String userId;
  final DevicePlatform platform;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final bool isActive;
  final DateTime? lastSyncAt;
  final DateTime createdAt;

  DeviceConnection({
    required this.id,
    required this.userId,
    required this.platform,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    required this.isActive,
    this.lastSyncAt,
    required this.createdAt,
  });

  factory DeviceConnection.fromJson(Map<String, dynamic> json) {
    return DeviceConnection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      platform: DevicePlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => DevicePlatform.manual,
      ),
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.parse(json['token_expires_at'])
          : null,
      isActive: json['is_active'] as bool? ?? true,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'platform': platform.name,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expires_at': tokenExpiresAt?.toIso8601String(),
      'is_active': isActive,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DeviceIntegrationService {
  final _supabase = Supabase.instance.client;

  // Platform display names
  static const Map<DevicePlatform, String> platformNames = {
    DevicePlatform.strava: 'Strava',
    DevicePlatform.garmin: 'Garmin Connect',
    DevicePlatform.polar: 'Polar Flow',
    DevicePlatform.suunto: 'Suunto',
    DevicePlatform.coros: 'COROS',
    DevicePlatform.fitbit: 'Fitbit',
    DevicePlatform.whoop: 'Whoop',
    DevicePlatform.manual: 'Manual Upload',
  };

  // Platform descriptions
  static const Map<DevicePlatform, String> platformDescriptions = {
    DevicePlatform.strava: 'Sync activities, routes, and performance data',
    DevicePlatform.garmin:
        'Full biomechanics: ground contact time, VO2 max, recovery',
    DevicePlatform.polar: 'Heart rate zones, training load, sleep data',
    DevicePlatform.suunto: 'Activities, heart rate, altitude data',
    DevicePlatform.coros: 'Training effect, workout analysis',
    DevicePlatform.fitbit: 'Steps, heart rate, sleep, stress tracking',
    DevicePlatform.whoop: 'Recovery, strain, HRV analysis',
    DevicePlatform.manual: 'Import .FIT, .GPX, .TCX files',
  };

  // Get connected devices for current user
  Future<List<DeviceConnection>> getConnectedDevices() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        developer.log('❌ No user logged in');
        return [];
      }

      final response = await _supabase
          .from('device_connections')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      if (response.isEmpty) return [];

      return (response as List)
          .map((json) => DeviceConnection.fromJson(json))
          .toList();
    } catch (e) {
      developer.log('❌ Error getting connected devices: $e');
      return [];
    }
  }

  // Check if platform is connected
  Future<bool> isConnected(DevicePlatform platform) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('device_connections')
          .select('id')
          .eq('user_id', userId)
          .eq('platform', platform.name)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      developer.log('❌ Error checking connection: $e');
      return false;
    }
  }

  // Get device connection details
  Future<DeviceConnection?> getDeviceConnection(DevicePlatform platform) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('device_connections')
          .select()
          .eq('user_id', userId)
          .eq('platform', platform.name)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return DeviceConnection.fromJson(response);
    } catch (e) {
      developer.log('❌ Error getting device connection: $e');
      return null;
    }
  }

  // Save device connection
  Future<bool> saveConnection({
    required DevicePlatform platform,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiresAt,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        developer.log('❌ No user logged in');
        return false;
      }

      // Check if connection already exists
      final existing = await _supabase
          .from('device_connections')
          .select('id')
          .eq('user_id', userId)
          .eq('platform', platform.name)
          .maybeSingle();

      final data = {
        'user_id': userId,
        'platform': platform.name,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_expires_at': tokenExpiresAt?.toIso8601String(),
        'is_active': true,
        'last_sync_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        // Update existing connection
        await _supabase
            .from('device_connections')
            .update(data)
            .eq('id', existing['id']);
      } else {
        // Insert new connection
        await _supabase.from('device_connections').insert(data);
      }

      developer.log('✅ Device connection saved: ${platform.name}');
      return true;
    } catch (e) {
      developer.log('❌ Error saving connection: $e');
      return false;
    }
  }

  // Disconnect device
  Future<bool> disconnectDevice(DevicePlatform platform) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('device_connections')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('platform', platform.name);

      developer.log('✅ Device disconnected: ${platform.name}');
      return true;
    } catch (e) {
      developer.log('❌ Error disconnecting device: $e');
      return false;
    }
  }

  // Update last sync time
  Future<void> updateLastSync(DevicePlatform platform) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('device_connections')
          .update({'last_sync_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('platform', platform.name);

      developer.log('✅ Last sync updated: ${platform.name}');
    } catch (e) {
      developer.log('❌ Error updating last sync: $e');
    }
  }

  // Get device status summary
  Future<Map<String, dynamic>> getDeviceStatus(DevicePlatform platform) async {
    try {
      final connection = await getDeviceConnection(platform);

      if (connection == null) {
        return {
          'connected': false,
          'platform': platform.name,
          'lastSync': null,
          'status': 'Not connected',
        };
      }

      final lastSyncText = connection.lastSyncAt != null
          ? _formatLastSync(connection.lastSyncAt!)
          : 'Never synced';

      return {
        'connected': true,
        'platform': platform.name,
        'lastSync': connection.lastSyncAt?.toIso8601String(),
        'lastSyncText': lastSyncText,
        'status': 'Connected',
        'tokenExpires': connection.tokenExpiresAt?.toIso8601String(),
      };
    } catch (e) {
      developer.log('❌ Error getting device status: $e');
      return {
        'connected': false,
        'platform': platform.name,
        'status': 'Error',
      };
    }
  }

  // Format last sync time as human-readable
  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }

  // Get all platforms with connection status
  Future<List<Map<String, dynamic>>> getAllPlatformsStatus() async {
    final List<Map<String, dynamic>> platforms = [];

    for (final platform in DevicePlatform.values) {
      if (platform == DevicePlatform.manual) continue; // Skip manual

      final status = await getDeviceStatus(platform);
      platforms.add({
        'platform': platform,
        'name': platformNames[platform],
        'description': platformDescriptions[platform],
        'connected': status['connected'],
        'lastSync': status['lastSyncText'],
        'status': status['status'],
      });
    }

    return platforms;
  }

  // Sync activities from platform (placeholder - implement in specific services)
  Future<int> syncActivities(DevicePlatform platform) async {
    try {
      developer.log('🔄 Syncing activities from ${platform.name}...');

      // TODO: Call specific platform service based on platform
      // For now, just update last sync time
      await updateLastSync(platform);

      developer.log('✅ Activities synced from ${platform.name}');
      return 0; // Return number of new activities
    } catch (e) {
      developer.log('❌ Error syncing activities: $e');
      return 0;
    }
  }
}
