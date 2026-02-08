// GPS Watch Connection Management Screen
//
// Allows users to:
// - Connect Strava account via OAuth
// - View connection status
// - Test API connection
// - Sync activities
// - Disconnect account
//
// Date: February 5, 2026

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/strava_oauth_service.dart';
import '../services/gps_data_fetcher.dart';
import 'dart:developer' as developer;

class GPSConnectionScreen extends StatefulWidget {
  const GPSConnectionScreen({super.key});

  @override
  State<GPSConnectionScreen> createState() => _GPSConnectionScreenState();
}

class _GPSConnectionScreenState extends State<GPSConnectionScreen> {
  final StravaOAuthService _stravaOAuth = StravaOAuthService();
  final GPSDataFetcher _gpsDataFetcher = GPSDataFetcher();
  final _supabase = Supabase.instance.client;

  bool _isStravaConnected = false;
  bool _isLoading = true;
  Map<String, dynamic>? _athleteProfile;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // Check if Strava is connected
      final connectionStatus = await _gpsDataFetcher.checkConnectionStatus();
      _isStravaConnected = connectionStatus[GPSPlatform.strava] ?? false;

      // Get athlete profile if connected
      if (_isStravaConnected) {
        _athleteProfile = await _stravaOAuth.getAthleteProfile();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error checking connection: $e';
      });
    }
  }

  Future<void> _connectStrava() async {
    try {
      // Check if user is logged in first
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ Login Required'),
              content: const Text(
                'You need to be logged into SafeStride before connecting your Strava account.\n\n'
                'Please:\n'
                '1. Go back to the home screen\n'
                '2. Sign in or create an account\n'
                '3. Then return here to connect Strava',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to profile/home
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          );
        }
        return;
      }

      setState(() {
        _statusMessage = 'Generating authorization URL...';
      });

      // Get authorization URL
      final authUrl = _stravaOAuth.getAuthorizationUrl();

      // Show URL in dialog for manual testing
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Connect to Strava'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copy this URL and open it in your browser:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      authUrl,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Steps:\n'
                    '1. Copy the URL above\n'
                    '2. Paste it in a NEW BROWSER TAB\n'
                    '3. Login and authorize SafeStride\n'
                    '4. After authorizing, you\'ll see "This site can\'t be reached"\n'
                    '5. In the URL bar, find "code=" and copy EVERYTHING after it\n'
                    '   (until the next & or end of URL)\n'
                    '6. Come back here and click the button below',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAuthCodeDialog();
                },
                child: const Text('I\'ve Authorized, Enter Code'),
              ),
            ],
          ),
        );
      }

      setState(() {
        _statusMessage = 'Follow the instructions in the dialog above';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  void _showAuthCodeDialog() {
    final codeController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Strava Authorization Code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎉 You authorized SafeStride on Strava!\n\n'
                'After clicking Authorize, Strava redirected you to a page '
                'that says "This site can\'t be reached". This is NORMAL!\n',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                '📋 Choose ONE option:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'OPTION 1: Paste the full redirect URL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Text(
                'Copy the entire URL from browser address bar:',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Full URL (starts with localhost/?...)',
                  hintText: 'localhost/?state=...&code=...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 11),
                maxLines: 3,
                onChanged: (value) {
                  // Auto-extract code from URL
                  final uri = Uri.tryParse('http://$value');
                  if (uri != null && uri.queryParameters.containsKey('code')) {
                    codeController.text = uri.queryParameters['code'] ?? '';
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'OPTION 2: Paste just the code',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Text(
                'Find "code=" in URL and copy everything after it:',
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Authorization Code',
                  hintText: 'Long alphanumeric string',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String code = codeController.text.trim();

              // If code is empty, try to extract from URL
              if (code.isEmpty && urlController.text.isNotEmpty) {
                final uri = Uri.tryParse('http://${urlController.text}');
                if (uri != null && uri.queryParameters.containsKey('code')) {
                  code = uri.queryParameters['code'] ?? '';
                }
              }

              if (code.isNotEmpty) {
                Navigator.pop(context);
                await _exchangeAuthCode(code);
              } else {
                // Show error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please enter either the full URL or just the code'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC4C02),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _exchangeAuthCode(String code) async {
    setState(() {
      _statusMessage = 'Exchanging authorization code...';
    });

    try {
      final result = await _stravaOAuth.exchangeCodeForToken(code);

      if (result['success'] == true) {
        setState(() {
          _statusMessage = '✅ Successfully connected to Strava!\n\n'
              'Athlete: ${result['athlete']['firstname']} ${result['athlete']['lastname']}';
          _isStravaConnected = true;
        });

        // Refresh connection status
        await _checkConnectionStatus();

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('🎉 Connected!'),
              content: Text(
                'Strava account connected successfully!\n\n'
                'Athlete: ${result['athlete']['firstname']} ${result['athlete']['lastname']}\n'
                'ID: ${result['athlete']['id']}',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _statusMessage = '❌ Connection failed:\n${result['error']}';
        });

        // Show detailed error dialog with login guidance
        if (mounted) {
          final errorMsg = result['error']?.toString() ?? 'Unknown error';
          final errorDetails = result['details']?.toString() ?? '';
          final isLoginError = errorMsg.contains('not logged in') ||
              errorMsg.contains('User not');

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                  isLoginError ? '⚠️ Login Required' : '❌ Connection Failed'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isLoginError
                        ? 'You need to be logged into SafeStride first!'
                        : 'Error: $errorMsg'),
                    if (errorDetails.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Details: $errorDetails',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      isLoginError
                          ? 'Please:\n1. Go back to home screen\n2. Sign in or create account\n3. Return here and connect Strava'
                          : 'Please try again or check your internet connection.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isLoginError)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back
                    },
                    child: const Text('Go to Login'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _statusMessage = 'Testing Strava API connection...';
    });

    try {
      final result = await _stravaOAuth.testConnection();

      if (result['success'] == true) {
        setState(() {
          _statusMessage = '✅ Strava API working!\n\n'
              'Athlete: ${result['athlete']['firstname']} ${result['athlete']['lastname']}\n'
              'Activities: ${result['athlete']['athlete_type']}';
        });
      } else {
        setState(() {
          _statusMessage = '❌ Connection test failed:\n${result['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  Future<void> _syncActivities() async {
    setState(() {
      _statusMessage =
          'Syncing ALL activities from Strava...\n(This may take a few minutes for many activities)';
    });

    try {
      // Fetch ALL activities from day 1 (no date limits, no activity limit)
      developer.log('🔄 Starting full sync of ALL Strava activities...');

      final activities = await _gpsDataFetcher.fetchFromPlatform(
        platform: GPSPlatform.strava,
        // No startDate = fetch from the beginning
        // No endDate = fetch until now
        // No limit = fetch everything
      );

      developer.log('✅ Fetched ${activities.length} total activities');

      // Save activities to database with calendar date organization
      setState(() {
        _statusMessage =
            'Saving ${activities.length} activities to database...\nOrganizing by calendar date...';
      });

      final saveResult =
          await _gpsDataFetcher.saveActivitiesToDatabase(activities);
      final savedCount = saveResult['savedCount'] as int;
      final uniqueDates = saveResult['uniqueDates'] as int;

      setState(() {
        _statusMessage =
            '✅ Successfully synced ${activities.length} activities!\n'
            '💾 $savedCount new activities saved\n'
            '📅 Organized across $uniqueDates calendar dates';
      });

      // Show activities dialog with calendar date information
      if (mounted && activities.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title:
                const Text('✅ Activities Synced & Organized by Calendar Date'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📅 CALENDAR DATE ORGANIZATION',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text('📊 Total Activities: ${activities.length}',
                            style: const TextStyle(fontSize: 12)),
                        Text('💾 New Activities Saved: $savedCount',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        Text('📅 Unique Calendar Dates: $uniqueDates',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        const SizedBox(height: 4),
                        Text(
                            '📆 From: ${activities.last.startTime.toString().split(' ')[0]}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                            '📆 To: ${activities.first.startTime.toString().split(' ')[0]}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recent Activities (with complete metrics):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          activities.length > 15 ? 15 : activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ExpansionTile(
                            leading: const Icon(Icons.directions_run,
                                color: Colors.blue),
                            title: Text(
                              '${(activity.distanceMeters / 1000).toStringAsFixed(2)} km',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '📅 ${activity.startTime.toString().split(' ')[0]} • '
                              '${(activity.durationSeconds / 60).round()} min',
                              style: const TextStyle(fontSize: 12),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (activity.avgCadence != null)
                                      _buildMetricRow('Cadence',
                                          '${activity.avgCadence!.round()} spm'),
                                    if (activity.avgStrideLength != null)
                                      _buildMetricRow('Stride Length',
                                          '${activity.avgStrideLength!.toStringAsFixed(2)} m'),
                                    if (activity.avgHeartRate != null)
                                      _buildMetricRow('Heart Rate',
                                          '${activity.avgHeartRate!.round()} bpm'),
                                    if (activity.avgSpeed != null)
                                      _buildMetricRow('Avg Speed',
                                          '${activity.avgSpeed!.toStringAsFixed(1)} km/h'),
                                    if (activity.avgPace != null)
                                      _buildMetricRow('Avg Pace',
                                          '${activity.avgPace!.toStringAsFixed(2)} min/km'),
                                    if (activity.elevationGain != null)
                                      _buildMetricRow('Elevation Gain',
                                          '${activity.elevationGain!.round()} m'),
                                    if (activity.calories != null)
                                      _buildMetricRow('Calories',
                                          '${activity.calories} kcal'),
                                    if (activity.avgWatts != null)
                                      _buildMetricRow('Power',
                                          '${activity.avgWatts!.round()} W'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      developer.log('❌ Sync error: $e');
      setState(() {
        _statusMessage = '❌ Sync failed: $e';
      });
    }
  }

  Future<void> _disconnectStrava() async {
    // Confirm disconnect
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Strava?'),
        content: const Text(
          'This will remove your Strava connection and stop syncing activities. '
          'You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _statusMessage = 'Disconnecting Strava...';
      });

      try {
        await _stravaOAuth.disconnect();
        setState(() {
          _isStravaConnected = false;
          _athleteProfile = null;
          _statusMessage = '✅ Strava disconnected successfully';
        });
      } catch (e) {
        setState(() {
          _statusMessage = '❌ Error disconnecting: $e';
        });
      }
    }
  }

  // Helper method to build metric rows in activity details
  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Watch Connection'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    'Connect Your GPS Watch',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sync your running activities to get personalized injury prevention protocols.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Strava Connection Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFC4C02),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.directions_run,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Strava',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _isStravaConnected
                                          ? '✅ Connected'
                                          : '⚪ Not connected',
                                      style: TextStyle(
                                        color: _isStravaConnected
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _isStravaConnected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: _isStravaConnected
                                    ? Colors.green
                                    : Colors.grey,
                                size: 32,
                              ),
                            ],
                          ),

                          // Athlete Profile (if connected)
                          if (_isStravaConnected &&
                              _athleteProfile != null) ...[
                            const Divider(height: 32),
                            Row(
                              children: [
                                if (_athleteProfile!['strava_profile_image'] !=
                                    null)
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      _athleteProfile!['strava_profile_image'],
                                    ),
                                  )
                                else
                                  const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_athleteProfile!['strava_firstname']} ${_athleteProfile!['strava_lastname']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '@${_athleteProfile!['strava_username']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Action Buttons
                          if (!_isStravaConnected)
                            ElevatedButton.icon(
                              onPressed: _connectStrava,
                              icon: const Icon(Icons.link),
                              label: const Text('Connect Strava'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFC4C02),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            )
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _testConnection,
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Test'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _syncActivities,
                                    icon: const Icon(Icons.sync, size: 18),
                                    label: const Text('Sync'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _disconnectStrava,
                              icon: const Icon(Icons.link_off, size: 18),
                              label: const Text('Disconnect'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Status Message
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],

                  // Coming Soon (Garmin & Coros)
                  const SizedBox(height: 24),
                  const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.grey[200],
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.watch, color: Colors.grey),
                            title: Text(
                              'Garmin Connect',
                              style: TextStyle(color: Colors.grey),
                            ),
                            subtitle: Text('Coming soon'),
                          ),
                          ListTile(
                            leading: Icon(Icons.watch, color: Colors.grey),
                            title: Text(
                              'Coros Training Hub',
                              style: TextStyle(color: Colors.grey),
                            ),
                            subtitle: Text('Coming soon'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),
        ),
    );
  }
}
