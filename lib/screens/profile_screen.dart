import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/strava_service.dart';
import '../services/strava_protocol_service.dart';
import '../services/workout_analysis_service.dart';
import 'analysis_report_screen.dart';
import 'login_screen.dart';
import 'dart:developer' as developer;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = 'Loading...';
  String userEmail = '';
  double weeklyGoal = 50.0;
  bool isLoading = true;

  // Strava connection state
  final _stravaService = StravaService();
  bool isStravaConnected = false;
  Map<String, dynamic>? stravaInfo;
  bool isSyncingStrava = false;

  // Protocol generation state
  bool _isGenerating = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkStravaConnection();
  }

  Future<void> _analyzeWorkoutData() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Analyzing your workout data...'),
              ],
            ),
            duration: const Duration(seconds: 10),
            backgroundColor: Colors.blue[700],
          ),
        );
      }

      // Fetch Strava activities (mock data for testing)
      final stravaActivities = await _fetchStravaActivitiesForAnalysis();

      // Fetch AISRI data (mock data for testing)
      final aisriData = {
        'score': 52,
        'recovery_score': 55,
        'pillar_scores': {
          'adaptability': 65,
          'injury_risk': 45,
          'fatigue': 58,
          'recovery': 52,
          'intensity': 48,
          'consistency': 62,
        },
      };

      // Perform analysis
      final analysis = WorkoutAnalysisService.analyzeWorkoutData(
        workoutData: {},
        aisriData: aisriData,
        stravaActivities: stravaActivities,
      );

      // Hide loading
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Navigate to analysis report screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisReportScreen(analysis: analysis),
          ),
        );
      }
    } catch (e) {
      developer.log('Error analyzing data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStravaActivitiesForAnalysis() async {
    // For testing: Return mock Strava activities with problematic metrics
    return [
      {
        'id': 1,
        'name': 'Morning Run',
        'distance': 8000, // 8km
        'moving_time': 2880, // 48 minutes
        'cadence': 155, // LOW - issue
        'average_heartrate': 165,
        'vertical_oscillation': 11.2, // HIGH - issue
        'ground_contact_time': 285, // HIGH - issue
        'total_elevation_gain': 45,
      },
      {
        'id': 2,
        'name': 'Easy Run',
        'distance': 6000,
        'moving_time': 2400,
        'cadence': 158,
        'average_heartrate': 155,
        'vertical_oscillation': 10.8,
        'ground_contact_time': 290,
        'total_elevation_gain': 30,
      },
      {
        'id': 3,
        'name': 'Long Run',
        'distance': 12000,
        'moving_time': 4320,
        'cadence': 152,
        'average_heartrate': 160,
        'vertical_oscillation': 11.5,
        'ground_contact_time': 295,
        'total_elevation_gain': 80,
      },
    ];
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final user = Supabase.instance.client.auth.currentUser;

      // For testing: Use mock data if not authenticated
      if (userId == null || user == null) {
        setState(() {
          userName = 'KURA SATHYAMOORTHY BALENDAR';
          userEmail = 'test@safestride.com';
          weeklyGoal = 50.0;
          isLoading = false;
        });
        return;
      }

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('name, weekly_goal_distance')
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        userName = profileResponse?['name'] ?? 'Athlete';
        userEmail = user.email ?? '';
        weeklyGoal =
            (profileResponse?['weekly_goal_distance'] ?? 50.0).toDouble();
        isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading profile: $e');
      setState(() {
        userName = 'KURA SATHYAMOORTHY BALENDAR';
        userEmail = 'test@safestride.com';
        weeklyGoal = 50.0;
        isLoading = false;
      });
    }
  }

  Future<void> _checkStravaConnection() async {
    final connected = await _stravaService.isConnected();
    final info = await _stravaService.getConnectionInfo();
    setState(() {
      isStravaConnected = connected;
      stravaInfo = info;
    });
  }

  Future<void> _connectStrava() async {
    final success = await _stravaService.connectStrava();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening Strava authorization...'),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open Strava authorization'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateProtocol() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Show loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Analyzing your data...'),
              ],
            ),
            duration: const Duration(seconds: 10),
            backgroundColor: Colors.blue[700],
          ),
        );
      }

      final service = StravaProtocolService();
      final result = await service.generateAndScheduleProtocol(
        clearExisting: false,
      );

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (result.success && mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Success!'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result.detailedSummary,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Workouts added to your calendar',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to calendar tab (index 2 in bottom nav)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('View Calendar'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        // Show error
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Error'),
              ],
            ),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Show error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Error'),
              ],
            ),
            content: Text('Failed to generate protocol: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _syncStrava() async {
    setState(() => isSyncingStrava = true);

    try {
      final count = await _stravaService.syncActivities();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Synced $count activities from Strava! 🎉'
                : 'No new activities to sync'),
            backgroundColor: count > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSyncingStrava = false);
      }
    }
  }

  Future<void> _disconnectStrava() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Strava?'),
        content: const Text(
            'Your synced workouts will remain, but we will stop syncing new activities.'),
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

    if (confirm == true) {
      final success = await _stravaService.disconnect();
      if (success) {
        await _checkStravaConnection();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disconnected from Strava'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Profile Header
                Container(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.purple.shade100,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Account Settings Section
                Text(
                  'Account Settings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.person,
                        iconColor: Colors.purple,
                        title: 'Edit Profile',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.flag,
                        iconColor: Colors.purple,
                        title: 'Weekly Goals',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Notifications Section
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.notifications,
                        iconColor: Colors.green,
                        title: 'Push Notifications',
                        trailing: Text(
                          'Enabled',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.access_time,
                        iconColor: Colors.purple,
                        title: 'Reminder Times',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Data & Sync Section
                Text(
                  'Data & Sync',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Strava Connection
                      _MenuItem(
                        icon: Icons.directions_run,
                        iconColor: Colors.orange,
                        title: 'Connect to Strava',
                        subtitle: isStravaConnected
                            ? stravaInfo != null
                                ? 'Connected ${_formatDate(stravaInfo!['connected_at'])}'
                                : 'Connected ✓'
                            : 'Sync your workouts automatically',
                        trailing: isStravaConnected
                            ? const Icon(Icons.check_circle,
                                color: Colors.green, size: 24)
                            : ElevatedButton(
                                onPressed: _connectStrava,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Connect'),
                              ),
                        onTap: isStravaConnected
                            ? _disconnectStrava
                            : _connectStrava,
                      ),

                      // Sync Now button (only if connected)
                      if (isStravaConnected) ...[
                        const Divider(height: 1),
                        _MenuItem(
                          icon: Icons.sync,
                          iconColor: Colors.blue,
                          title: 'Sync Now',
                          subtitle: 'Import recent activities from Strava',
                          trailing: isSyncingStrava
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: isSyncingStrava ? null : _syncStrava,
                        ),
                      ],

                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.upload,
                        iconColor: Colors.purple,
                        title: 'Export Data',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Analyze Workout Data Section
                Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3),
                                    Color(0xFF64B5F6)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.analytics,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI-Powered Analysis',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Identify issues & get remedies',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Get a comprehensive analysis of your workout data. Identify biomechanical issues (cadence, vertical oscillation, ground contact time) with AI-powered insights and personalized remedies.',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isAnalyzing ? null : _analyzeWorkoutData,
                            icon: _isAnalyzing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.insights),
                            label: Text(_isAnalyzing
                                ? 'Analyzing...'
                                : 'Analyze My Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Generate Protocol Section
                Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF66BB6A)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.fitness_center,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Generate Workout Protocol',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create personalized workouts',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Based on your AISRI assessment and Strava data, we\'ll create a 2-week workout protocol with 6 personalized exercises.',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _generateProtocol,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isGenerating
                                ? 'Generating...'
                                : 'Generate Protocol'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // About Section
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.bar_chart,
                        iconColor: Colors.red,
                        title: 'App Version 1.0.0',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.help,
                        iconColor: Colors.blue,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      _MenuItem(
                        icon: Icons.privacy_tip,
                        iconColor: Colors.grey,
                        title: 'Privacy Policy',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Log Out Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content:
                              const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        // Sign out
                        await context.read<AuthService>().signOut();

                        // Navigate to login screen and clear navigation stack
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              ),
        ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return '';
    }
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]))
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}
