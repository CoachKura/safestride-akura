// lib/screens/garmin_connect_screen.dart
//
// Garmin Connect Integration Screen
// Allows users to connect their Garmin account via OAuth
// Displays connection status, devices, and sync options

import 'package:flutter/material.dart';
import '../services/garmin_oauth_service.dart';
import '../theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class GarminConnectScreen extends StatefulWidget {
  const GarminConnectScreen({Key? key}) : super(key: key);

  @override
  State<GarminConnectScreen> createState() => _GarminConnectScreenState();
}

class _GarminConnectScreenState extends State<GarminConnectScreen> {
  final GarminOAuthService _garminService = GarminOAuthService();
  
  bool _isConnected = false;
  bool _isLoading = true;
  bool _isSyncing = false;
  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);
    
    try {
      final connected = await _garminService.isConnected();
      final status = await _garminService.getConnectionStatus();
      
      setState(() {
        _isConnected = connected;
        _connectionStatus = status;
        _isLoading = false;
      });

      if (connected) {
        await _loadDevices();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error checking connection: $e');
    }
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await _garminService.getDevices();
      setState(() => _devices = devices);
    } catch (e) {
      _showError('Error loading devices: $e');
    }
  }

  Future<void> _connect() async {
    try {
      // Get authorization URL
      const redirectUri = 'io.supabase.safestride://garmin-callback';
      final authUrl = await _garminService.getAuthorizationUrl(redirectUri);

      // Launch browser for OAuth
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show instructions
        if (!mounted) return;
        _showInstructions();
      } else {
        _showError('Could not launch browser');
      }
    } catch (e) {
      _showError('Error connecting: $e');
    }
  }

  Future<void> _syncActivities() async {
    setState(() => _isSyncing = true);
    
    try {
      final activities = await _garminService.syncActivities();
      
      if (!mounted) return;
      setState(() => _isSyncing = false);
      
      _showSuccess('Synced ${activities.length} activities from Garmin');
      await _checkConnection(); // Refresh status
    } catch (e) {
      setState(() => _isSyncing = false);
      _showError('Error syncing: $e');
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Garmin?'),
        content: const Text(
          'Your Garmin data will no longer sync automatically. '
          'You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _garminService.disconnect();
        await _checkConnection();
        if (!mounted) return;
        _showSuccess('Disconnected from Garmin');
      } catch (e) {
        _showError('Error disconnecting: $e');
      }
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Almost There!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete authorization in your browser, then return to this app.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppPadding.md,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: AppRadius.defaultRadius,
                border: Border.all(color: AppColors.info),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tip: If the browser doesn\'t open, check your browser settings.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garmin Connect'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkConnection,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppPadding.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Garmin Branding
                    _buildHeader(),
                    
                    const SizedBox(height: AppSpacing.lg),

                    // Connection Status Card
                    _buildConnectionStatus(),

                    const SizedBox(height: AppSpacing.lg),

                    // Main Action (Connect/Sync/Disconnect)
                    if (!_isConnected)
                      _buildConnectSection()
                    else ...[
                      _buildSyncSection(),
                      const SizedBox(height: AppSpacing.md),
                      _buildDevicesSection(),
                      const SizedBox(height: AppSpacing.md),
                      _buildDisconnectButton(),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Benefits Section
                    _buildBenefitsSection(),

                    const SizedBox(height: AppSpacing.lg),

                    // Support Section
                    _buildSupportSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: AppPadding.lg,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0066CC), Color(0xFF004499)],
        ),
        borderRadius: AppRadius.largeRadius,
        boxShadow: AppShadows.cardShadows,
      ),
      child: Column(
        children: [
          // Garmin Logo (using text for now - replace with actual logo)
          Text(
            'GARMIN',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Connect with Garmin Connect',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final status = _connectionStatus;
    final isConnected = status?['connected'] == true;

    return Container(
      padding: AppPadding.md,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppRadius.defaultRadius,
        boxShadow: AppShadows.cardShadows,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnected ? Icons.check_circle : Icons.warning_amber,
              color: isConnected ? AppColors.success : AppColors.warning,
              size: AppSpacing.iconSizeLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (isConnected && status != null) ...[
                  Text(
                    '${status['activity_count'] ?? 0} activities • ${status['device_count'] ?? 0} devices',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (status['last_sync'] != null)
                    Text(
                      'Last sync: ${_formatDate(status['last_sync'])}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ] else
                  Text(
                    'Connect to sync workouts and data',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _connect,
          icon: const Icon(Icons.link),
          label: const Text('Connect to Garmin'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: AppPadding.md,
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: AppRadius.defaultRadius,
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Requires Garmin Connect account',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncSection() {
    return Container(
      padding: AppPadding.md,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppRadius.defaultRadius,
        boxShadow: AppShadows.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity Sync', style: AppTextStyles.titleMedium),
              if (_isSyncing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Import your Garmin workouts to SafeStride',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _syncActivities,
            icon: const Icon(Icons.sync),
            label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesSection() {
    if (_devices.isEmpty) {
      return Container(
        padding: AppPadding.md,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: AppRadius.defaultRadius,
        ),
        child: Column(
          children: [
            Icon(
              Icons.watch_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No devices found',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Connect a Garmin watch to your Garmin Connect account',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: AppPadding.md,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppRadius.defaultRadius,
        boxShadow: AppShadows.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Connected Devices', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final device in _devices)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: const Icon(
                      Icons.watch,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device['device_name'] ?? 'Unknown Device',
                          style: AppTextStyles.titleSmall,
                        ),
                        if (device['last_sync_at'] != null)
                          Text(
                            'Last sync: ${_formatDate(device['last_sync_at'])}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return OutlinedButton.icon(
      onPressed: _disconnect,
      icon: const Icon(Icons.link_off),
      label: const Text('Disconnect Garmin'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: AppPadding.md,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: AppRadius.defaultRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why Connect Garmin?', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _buildBenefitItem(
            icon: Icons.upload_rounded,
            title: 'Send Workouts to Watch',
            description: 'Push structured workouts directly to your Garmin device',
          ),
          _buildBenefitItem(
            icon: Icons.sync_rounded,
            title: 'Auto-Sync Activities',
            description: 'Import runs automatically after each workout',
          ),
          _buildBenefitItem(
            icon: Icons.insights_rounded,
            title: 'Training Insights',
            description: 'Access VO2 Max, training load, and recovery time',
          ),
          _buildBenefitItem(
            icon: Icons.favorite_rounded,
            title: 'AISRI Zone Guidance',
            description: 'Real-time zone alerts with our Connect IQ app',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: AppPadding.md,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.defaultRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Need Help?', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Visit our support page for Garmin connection troubleshooting.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () {
              // Open support page
              launchUrl(Uri.parse('https://support.safestride.app/garmin'));
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View Support'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Never';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes}m ago';
      if (difference.inDays < 1) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      
      return'${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
