// Devices Screen
// Multi-platform fitness device connection management
// Connect Strava, Garmin, Polar, Suunto, COROS, Fitbit, Whoop

import 'package:flutter/material.dart';
import '../services/device_integration_service.dart';
import '../services/strava_service.dart';
import 'dart:developer' as developer;

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _deviceService = DeviceIntegrationService();
  final _stravaService = StravaService();

  List<Map<String, dynamic>> _platforms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final platforms = await _deviceService.getAllPlatformsStatus();
      setState(() {
        _platforms = platforms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load platforms: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectPlatform(DevicePlatform platform) async {
    try {
      bool success = false;

      switch (platform) {
        case DevicePlatform.strava:
          // Use Strava service for OAuth flow
          developer.log('🔄 Connecting to Strava...');
          await _stravaService.connectStrava();
          success = true;
          break;

        case DevicePlatform.garmin:
          // TODO: Implement Garmin OAuth
          _showComingSoonDialog('Garmin Connect');
          break;

        case DevicePlatform.polar:
          _showComingSoonDialog('Polar Flow');
          break;

        case DevicePlatform.suunto:
          _showComingSoonDialog('Suunto');
          break;

        case DevicePlatform.coros:
          _showComingSoonDialog('COROS');
          break;

        case DevicePlatform.fitbit:
          _showComingSoonDialog('Fitbit');
          break;

        case DevicePlatform.whoop:
          _showComingSoonDialog('Whoop');
          break;

        case DevicePlatform.manual:
          _showManualUploadDialog();
          break;
      }

      if (success) {
        await _loadPlatforms(); // Refresh status
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('❌ Error connecting platform: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectPlatform(DevicePlatform platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Device'),
        content: Text(
          'Are you sure you want to disconnect ${DeviceIntegrationService.platformNames[platform]}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _deviceService.disconnectDevice(platform);
        await _loadPlatforms(); // Refresh status

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disconnected successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to disconnect: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _syncPlatform(DevicePlatform platform) async {
    try {
      developer.log('🔄 Syncing ${platform.name}...');

      // Show loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Syncing ${DeviceIntegrationService.platformNames[platform]}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Sync activities
      final newActivities = await _deviceService.syncActivities(platform);

      await _loadPlatforms(); // Refresh status

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newActivities > 0
                  ? '✅ Synced $newActivities new activities'
                  : '✅ Sync complete - no new activities',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Error syncing platform: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoonDialog(String platformName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$platformName Integration'),
        content: Text(
          '$platformName integration is coming soon!\n\nWe\'re working on bringing you seamless $platformName connectivity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual File Upload'),
        content: const Text(
          'Manual file upload (.FIT, .GPX, .TCX) is coming soon!\n\nYou\'ll be able to upload activity files directly from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlatforms,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPlatforms,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlatforms,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header Card
                      Card(
                        color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.sync,
                                size: 48,
                                color: Color(0xFF00D9FF),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Multi-Platform Integration',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Connect your favorite fitness platforms to sync activities and get comprehensive AI-powered analytics',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Connected Devices Section
                      const Text(
                        'AVAILABLE PLATFORMS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Platform Cards
                      ..._platforms
                          .map((platform) => _buildPlatformCard(platform)),

                      // Manual Upload Card
                      _buildManualUploadCard(),

                      const SizedBox(height: 24),

                      // Info Card
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Why Connect Devices?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '• Get AI-powered injury risk predictions\n'
                                '• Analyze running biomechanics and form\n'
                                '• Track training load and fatigue\n'
                                '• Receive personalized training plans\n'
                                '• Compare data across platforms',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPlatformCard(Map<String, dynamic> platformData) {
    final platform = platformData['platform'] as DevicePlatform;
    final name = platformData['name'] as String;
    final description = platformData['description'] as String;
    final connected = platformData['connected'] as bool;
    final lastSync = platformData['lastSync'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: connected ? null : () => _connectPlatform(platform),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Platform Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: connected
                          ? const Color(0xFF00D9FF).withValues(alpha: 0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getPlatformIcon(platform),
                      color: connected ? const Color(0xFF00D9FF) : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Platform Name & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (connected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Connected',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (connected && lastSync != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Last sync: $lastSync',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action Button
                  if (connected)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'sync') {
                          _syncPlatform(platform);
                        } else if (value == 'disconnect') {
                          _disconnectPlatform(platform);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'sync',
                          child: Row(
                            children: [
                              Icon(Icons.sync, size: 18),
                              SizedBox(width: 8),
                              Text('Sync Now'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'disconnect',
                          child: Row(
                            children: [
                              Icon(Icons.link_off, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Disconnect',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _connectPlatform(platform),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Connect'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualUploadCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _showManualUploadDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual File Upload',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Import .FIT, .GPX, .TCX files directly',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showManualUploadDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPlatformIcon(DevicePlatform platform) {
    switch (platform) {
      case DevicePlatform.strava:
        return Icons.directions_run;
      case DevicePlatform.garmin:
        return Icons.watch;
      case DevicePlatform.polar:
        return Icons.favorite;
      case DevicePlatform.suunto:
        return Icons.explore;
      case DevicePlatform.coros:
        return Icons.timer;
      case DevicePlatform.fitbit:
        return Icons.fitness_center;
      case DevicePlatform.whoop:
        return Icons.spa;
      case DevicePlatform.manual:
        return Icons.upload_file;
    }
  }
}
