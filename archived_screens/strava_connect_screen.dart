// Strava Connection Screen
//
// Allows users to:
// - Connect their Strava account via OAuth
// - View connection status
// - Sync activities
// - Generate AI training plans
// - Disconnect Strava

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/strava_service.dart';
import 'training_plan_screen.dart';
import 'dart:developer' as developer;

class StravaConnectScreen extends StatefulWidget {
  const StravaConnectScreen({super.key});

  @override
  State<StravaConnectScreen> createState() => _StravaConnectScreenState();
}

class _StravaConnectScreenState extends State<StravaConnectScreen> {
  final StravaService _stravaService = StravaService();
  bool _isConnected = false;
  bool _isLoading = true;
  bool _isSyncing = false;
  int _activityCount = 0;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);

    try {
      final connected = await _stravaService.isConnected();
      setState(() {
        _isConnected = connected;
        _isLoading = false;
      });

      if (connected) {
        await _loadActivityCount();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadActivityCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final result = await Supabase.instance.client
            .from('gps_activities')
            .select('id')
            .eq('user_id', userId);

        setState(() {
          _activityCount = (result as List).length;
        });
      }
    } catch (e) {
      developer.log('Error loading activity count: $e');
    }
  }

  Future<void> _connectStrava() async {
    try {
      final launched = await _stravaService.connectStrava();

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Strava. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncActivities() async {
    setState(() => _isSyncing = true);

    try {
      final count = await _stravaService.syncActivities(perPage: 200);
      await _loadActivityCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Synced $count new activities!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Disconnect Strava?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your synced activities will remain, but new activities won\'t sync.',
          style: TextStyle(color: Colors.white70),
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

    if (confirm == true) {
      try {
        await _stravaService.disconnect();
        await _checkConnection();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Strava disconnected')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Strava'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.deepOrange))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Strava Logo Card
                    _buildStravaCard(),

                    const SizedBox(height: 24),

                    // Connection Status
                    _buildConnectionStatus(),

                    const SizedBox(height: 24),

                    // Action Buttons
                    if (!_isConnected)
                      _buildConnectButton()
                    else ...[
                      _buildSyncButton(),
                      const SizedBox(height: 12),
                      _buildAITrainingPlanButton(),
                      const SizedBox(height: 12),
                      _buildDisconnectButton(),
                    ],

                    const SizedBox(height: 32),

                    // Benefits Section
                    _buildBenefitsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStravaCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFC4C02), Color(0xFFE84100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_run, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'STRAVA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected
                ? '$_activityCount Activities Synced'
                : 'Connect Your Account',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_isConnected ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isConnected ? Icons.check_circle : Icons.link_off,
              color: _isConnected ? Colors.green : Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isConnected
                      ? 'Your activities are syncing automatically'
                      : 'Connect to sync your running activities',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed: _connectStrava,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFC4C02),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link, size: 24),
          SizedBox(width: 12),
          Text(
            'Connect to Strava',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return ElevatedButton(
      onPressed: _isSyncing ? null : _syncActivities,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSyncing
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Syncing...', style: TextStyle(fontSize: 16)),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync, size: 24),
                SizedBox(width: 12),
                Text('Sync Activities',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
    );
  }

  Widget _buildAITrainingPlanButton() {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingPlanScreen()),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 24),
          SizedBox(width: 12),
          Text(
            'Generate AI Training Plan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return OutlinedButton(
      onPressed: _disconnect,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 20),
          SizedBox(width: 8),
          Text('Disconnect Strava', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHY CONNECT STRAVA?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            Icons.analytics,
            'AI Training Plans',
            'Personalized 4-week plans based on your actual fitness data',
          ),
          _buildBenefitItem(
            Icons.auto_graph,
            'Performance Tracking',
            'Track progress with pace, distance, and heart rate trends',
          ),
          _buildBenefitItem(
            Icons.calendar_month,
            'Activity Calendar',
            'View all your runs organized by date with detailed metrics',
          ),
          _buildBenefitItem(
            Icons.health_and_safety,
            'Injury Prevention',
            'Detect overtraining patterns before injuries occur',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
