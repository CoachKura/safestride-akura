import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/strava_complete_sync_service.dart';
import '../screens/athlete_dashboard.dart';

/// Complete Strava OAuth Signup Screen
///
/// Features:
/// - Sign up with Strava OAuth
/// - Auto-fill: name, age, gender, profile photo
/// - Pull all activity history (PBs, total mileage, stats)
/// - Background sync of 500+ activities
/// - Creates profile with complete data
class StravaSignupScreen extends StatefulWidget {
  const StravaSignupScreen({super.key});

  @override
  State<StravaSignupScreen> createState() => _StravaSignupScreenState();
}

class _StravaSignupScreenState extends State<StravaSignupScreen> {
  final _supabase = Supabase.instance.client;
  final _stravaSyncService = StravaCompleteSyncService();

  bool _isLoading = false;
  bool _isSigning = false;
  String? _errorMessage;
  Map<String, dynamic>? _athletePreview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade700,
              Colors.deepOrange.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_run,
                      size: 60,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'SafeStride',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'AI-Powered Injury-Free Training',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Athlete Preview (if loaded)
                  if (_athletePreview != null) ...[
                    _buildAthletePreview(),
                    const SizedBox(height: 24),
                  ],

                  // Sign Up with Strava Button
                  if (!_isSigning)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _initiateStravaSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFC4C02), // Strava orange
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Image.asset(
                              'assets/images/strava_icon.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.link),
                            ),
                      label: Text(
                        _isLoading ? 'Connecting...' : 'Sign Up with Strava',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Signing In Progress
                  if (_isSigning) ...[
                    _buildSigningProgress(),
                  ],

                  const SizedBox(height: 24),

                  // Benefits
                  Card(
                    color: Colors.white.withOpacity(0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What you get:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBenefit(
                            Icons.auto_awesome,
                            'Auto-filled profile',
                            'Name, age, stats from Strava',
                          ),
                          _buildBenefit(
                            Icons.history,
                            'Complete activity history',
                            'All your runs, PBs, total mileage',
                          ),
                          _buildBenefit(
                            Icons.trending_up,
                            'AISRI injury score',
                            'Based on your biomechanics data',
                          ),
                          _buildBenefit(
                            Icons.flash_on,
                            'Personalized timeline',
                            'Your journey to 3:30/km pace',
                          ),
                          _buildBenefit(
                            Icons.fitness_center,
                            'AI workouts',
                            'Daily workouts pushed to Garmin',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Terms
                  Text(
                    'By signing up, you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAthletePreview() {
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Photo
            if (_athletePreview!['profile'] != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_athletePreview!['profile']),
              )
            else
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),

            const SizedBox(height: 12),

            // Name
            Text(
              '${_athletePreview!['firstname']} ${_athletePreview!['lastname']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Stats Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatPreview(
                  Icons.directions_run,
                  '${_athletePreview!['activity_count'] ?? 0}',
                  'Activities',
                ),
                _buildStatPreview(
                  Icons.timer,
                  _formatDistance(_athletePreview!['total_distance'] ?? 0),
                  'Total km',
                ),
                _buildStatPreview(
                  Icons.calendar_today,
                  'Member',
                  _formatMemberSince(_athletePreview!['created_at']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPreview(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSigningProgress() {
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'Creating your account...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Syncing your Strava data\nThis may take a moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateStravaSignup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Initiate Strava OAuth
      final result = await _stravaSyncService.initiateStravaOAuth();

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to connect to Strava');
      }

      // 2. Show athlete preview
      setState(() {
        _athletePreview = result['athlete'];
        _isLoading = false;
      });

      // 3. Confirm and create account
      await _createAccountAndSync(result);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createAccountAndSync(Map<String, dynamic> stravaResult) async {
    setState(() {
      _isSigning = true;
      _errorMessage = null;
    });

    try {
      // 1. Create Supabase account
      final email = stravaResult['athlete']['email'] ??
          '${stravaResult['athlete']['id']}@strava.safestride.app';
      final password = _generateSecurePassword();

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'strava_athlete_id': stravaResult['athlete']['id'],
          'first_name': stravaResult['athlete']['firstname'],
          'last_name': stravaResult['athlete']['lastname'],
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account');
      }

      // 2. Store Strava tokens and profile
      await _stravaSyncService.storeStravaProfile(
        userId: authResponse.user!.id,
        athleteData: stravaResult['athlete'],
        accessToken: stravaResult['access_token'],
        refreshToken: stravaResult['refresh_token'],
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          stravaResult['expires_at'] * 1000,
        ),
      );

      // 3. Start background sync (activities, stats, PBs)
      _stravaSyncService.startBackgroundSync(authResponse.user!.id);

      // 4. Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AthleteDashboard(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSigning = false;
      });
    }
  }

  String _generateSecurePassword() {
    // Generate random secure password for Strava users
    return DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _formatDistance(num distance) {
    final km = (distance / 1000).round();
    return km.toString();
  }

  String _formatMemberSince(String? createdAt) {
    if (createdAt == null) return 'N/A';
    try {
      final date = DateTime.parse(createdAt);
      return '${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
