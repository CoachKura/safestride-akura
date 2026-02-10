import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'gps_tracker_screen.dart';
import '../services/aisri_calculator_service.dart';
import '../services/training_phase_manager.dart';
import 'dart:developer' as developer;

class StartRunScreen extends StatefulWidget {
  const StartRunScreen({super.key});

  @override
  State<StartRunScreen> createState() => _StartRunScreenState();
}

class _StartRunScreenState extends State<StartRunScreen> {
  String _selectedZone = 'F'; // Default to Foundation zone
  bool _isAnalyzing = false;
  Map<String, dynamic>? _aisriData;
  Map<String, dynamic>? _trainingPhase;
  List<Map<String, dynamic>> _hrZones = [];
  List<String> _allowedZones = [];
  Map<String, dynamic>? _safetyGates;

  @override
  void initState() {
    super.initState();
    _loadAISRIData();
  }

  Future<void> _loadAISRIData() async {
    setState(() => _isAnalyzing = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      // Fetch user profile for age and body metrics
      final profileResponse = await Supabase.instance.client
          .from('users')
          .select('date_of_birth, weight_kg, height_cm')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      // Calculate age
      final dob = DateTime.parse(profileResponse['date_of_birth']);
      final age = DateTime.now().difference(dob).inDays ~/ 365;
      final weightKg = profileResponse['weight_kg'] ?? 70.0;
      final heightCm = profileResponse['height_cm'] ?? 170.0;

      // Fetch recent workouts for load calculation
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final workoutsResponse = await Supabase.instance.client
          .from('workouts')
          .select('distance, distance_km, duration_minutes, created_at')
          .eq('user_id', userId)
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      // Calculate total lifetime km for phase tracking
      final allWorkoutsResponse = await Supabase.instance.client
          .from('workouts')
          .select('distance, distance_km')
          .eq('user_id', userId);

      final totalKm = (allWorkoutsResponse as List).fold<double>(
          0.0, (sum, w) => sum + ((w['distance'] ?? w['distance_km']) ?? 0.0));

      // Fetch injury history
      final injuriesResponse = await Supabase.instance.client
          .from('injuries')
          .select('injury_name, severity, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Fetch latest assessment data (if available)
      final assessmentResponse = await Supabase.instance.client
          .from('aisri_assessments')
          .select('assessment_data')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Fetch sleep data (placeholder - would come from health integration)
      final sleepData = {
        'hours': 7.5,
        'quality': 8,
      };

      // Calculate AISRI score
      final aisriResult = AISRICalculatorService.calculateAISRIScore(
        age: age,
        weightKg: weightKg,
        heightCm: heightCm,
        recentWorkouts: {
          'recent_runs': workoutsResponse,
        },
        injuryHistory: {
          'injuries': injuriesResponse,
        },
        sleepData: sleepData,
        assessmentData: assessmentResponse?['assessment_data'] ?? {},
        subjectiveFeel: 7, // Default to 7/10
      );

      // Get HR zones based on age
      final hrZones = AISRICalculatorService.calculateHRZones(age);

      // Get current training phase
      final trainingPhase = TrainingPhaseManager.getCurrentPhase(totalKm);

      // Convert HR zones Map to List format expected by UI
      final hrZonesList = (hrZones['zones'] as Map<String, dynamic>)
          .entries
          .map((entry) => {
                'zone': entry.key,
                'name': entry.value['name'],
                'min_hr': entry.value['min'],
                'max_hr': entry.value['max'],
                'purpose': entry.value['purpose'],
                'color': entry.value['color'],
                'is_core': entry.value['is_core'] ?? false,
                'requires_gate': entry.value['requires_gate'] ?? false,
              })
          .toList();

      setState(() {
        _aisriData = aisriResult;
        _hrZones = hrZonesList;
        _allowedZones = List<String>.from(aisriResult['allowed_zones']);
        _safetyGates = aisriResult['safety_gates'];
        _trainingPhase = trainingPhase;
        _isAnalyzing = false;

        // Auto-select highest allowed zone (or Foundation by default)
        if (_allowedZones.contains('TH')) {
          _selectedZone = 'TH'; // Threshold is the core zone
        } else if (_allowedZones.contains('EN')) {
          _selectedZone = 'EN';
        } else {
          _selectedZone = 'F';
        }
      });
    } catch (e) {
      developer.log('Error loading AISRI data: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  void _startRun(String zone) {
    // Check if zone is locked
    if (!_allowedZones.contains(zone)) {
      _showZoneLockedDialog(zone);
      return;
    }

    // Navigate to GPS tracker with selected zone
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GPSTrackerScreen(),
      ),
    );

    // TODO: Pass zone to GPSTrackerScreen for HR monitoring
  }

  void _showZoneLockedDialog(String zone) {
    final zoneData = _hrZones.firstWhere((z) => z['zone'] == zone);
    final zoneName = zoneData['name'];
    
    // Check if it's a safety-gated zone
    if (zone == 'P' && _safetyGates != null) {
      _showSafetyGateDialog('Power Zone', _safetyGates!['power']);
    } else if (zone == 'SP' && _safetyGates != null) {
      _showSafetyGateDialog('Speed Zone', _safetyGates!['speed']);
    } else {
      // General zone locked message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock, color: Colors.red),
              const SizedBox(width: 8),
              Text('$zoneName Locked'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This zone requires an AISRI score of ${_getRequiredScoreForZone(zone)} or higher.'),
              const SizedBox(height: 8),
              Text('Your current AISRI score: ${_aisriData?['aisri_score'] ?? 0}'),
              const SizedBox(height: 16),
              const Text(
                'How to unlock:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Complete strength and mobility assessments'),
              const Text('• Build aerobic base in lower zones'),
              const Text('• Improve recovery and sleep quality'),
              const Text('• Reduce injury risk factors'),
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
  }

  void _showSafetyGateDialog(String zoneName, Map<String, dynamic> gateData) {
    final requirements = gateData['requirements_met'] as Map<String, dynamic>;
    final allMet = requirements.values.every((v) => v == true);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              allMet ? Icons.check_circle : Icons.lock,
              color: allMet ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text('$zoneName Safety Gate'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!allMet) ...[
                const Text(
                  'This zone is locked for your safety. Complete the following requirements:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
              ],
              ...requirements.entries.map((entry) {
                final met = entry.value as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        met ? Icons.check_circle : Icons.cancel,
                        color: met ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatRequirementText(entry.key),
                          style: TextStyle(
                            color: met ? Colors.black87 : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatRequirementText(String key) {
    switch (key) {
      case 'aisri_score':
        return 'AISRI Score ≥ ${key == "aisri_score" ? (_safetyGates?['power']?['requirements_met']?['aisri_score'] == true ? "70" : "70+") : "75+"}';
      case 'rom_score':
        return 'Range of Motion ≥ 75';
      case 'no_recent_injuries':
        return 'No injuries in past 4 weeks';
      case 'training_weeks':
        return '8+ weeks in lower zones';
      case 'load_ratio':
        return 'Training load ratio ≤ 1.3';
      case 'all_pillars':
        return 'All 5 pillars ≥ 75';
      case 'perfect_form':
        return 'Perfect running form';
      case 'extended_training':
        return '12+ weeks including Power work';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  int _getRequiredScoreForZone(String zone) {
    switch (zone) {
      case 'TH':
        return 55;
      case 'P':
        return 70;
      case 'SP':
        return 75;
      case 'EN':
        return 40;
      default:
        return 0;
    }
  }

  Color _getReadinessColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'AR':
        return const Color(0xFF87CEEB); // Light blue
      case 'F':
        return const Color(0xFF4A90E2); // Blue
      case 'EN':
        return const Color(0xFF48D1CC); // Turquoise
      case 'TH':
        return const Color(0xFFFFA500); // Orange - CORE ZONE
      case 'P':
        return const Color(0xFFFF6B6B); // Red
      case 'SP':
        return const Color(0xFF8B0000); // Dark red
      default:
        return Colors.grey;
    }
  }

  IconData _getZoneIcon(String zone) {
    switch (zone) {
      case 'AR':
        return Icons.self_improvement;
      case 'F':
        return Icons.directions_walk;
      case 'EN':
        return Icons.landscape;
      case 'TH':
        return Icons.trending_up;
      case 'P':
        return Icons.flash_on;
      case 'SP':
        return Icons.speed;
      default:
        return Icons.run_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Run - AISRI Zones'),
        elevation: 0,
      ),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Calculating AISRI Zones...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AISRI Score Card
                  if (_aisriData != null)
                    Card(
                      elevation: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getReadinessColor(_aisriData!['aisri_score']),
                              _getReadinessColor(_aisriData!['aisri_score'])
                                  .withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.psychology,
                                    color: Colors.white, size: 32),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AISRI Score',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${_aisriData!['aisri_score']}/100',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _aisriData!['status_label'],
                                    style: TextStyle(
                                      color: _getReadinessColor(
                                          _aisriData!['aisri_score']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildMetric(
                                    'Recovery',
                                    '${_aisriData!['recovery_score']}/100',
                                    Colors.white),
                                _buildMetric(
                                    'Load',
                                    _aisriData!['risk_level'],
                                    Colors.white),
                                _buildMetric(
                                    'Zones',
                                    '${_allowedZones.length}/6',
                                    Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Training Phase Card
                  if (_trainingPhase != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timeline,
                                  color: Color(int.parse(
                                      _trainingPhase!['color']
                                          .replaceAll('#', '0xFF'))),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Phase ${_trainingPhase!['phase_number']}: ${_trainingPhase!['phase_name']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _trainingPhase!['progress_percent'] / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(int.parse(_trainingPhase!['color']
                                    .replaceAll('#', '0xFF'))),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_trainingPhase!['current_km'].toStringAsFixed(0)} km / ${_trainingPhase!['km_range']}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _trainingPhase!['focus'],
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // HR Zones Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select HR Training Zone',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Show info dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('AISRI Training Zones'),
                              content: const SingleChildScrollView(
                                child: Text(
                                  '6 heart rate zones based on the Economical Runner philosophy:\n\n'
                                  'AR (Active Recovery): Very light activity\n'
                                  'F (Foundation): Aerobic base building\n'
                                  'EN (Endurance): Steady state aerobic\n'
                                  'TH (Threshold): ⭐ CORE ZONE - lactate threshold\n'
                                  'P (Power): High intensity - requires safety gate\n'
                                  'SP (Speed): Sprint work - requires safety gate\n\n'
                                  'Zones unlock as your AISRI score improves.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Info'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // HR Zones Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _hrZones.length,
                    itemBuilder: (context, index) {
                      final zone = _hrZones[index];
                      final zoneCode = zone['zone'];
                      final isLocked = !_allowedZones.contains(zoneCode);
                      final isSelected = _selectedZone == zoneCode;
                      final isCoreZone = zoneCode == 'TH';
                      final requiresGate =
                          zone['requires_safety_gate'] == true;

                      return GestureDetector(
                        onTap: () {
                          if (isLocked) {
                            _showZoneLockedDialog(zoneCode);
                          } else {
                            setState(() => _selectedZone = zoneCode);
                          }
                        },
                        child: Card(
                          elevation: isSelected ? 8 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? _getZoneColor(zoneCode)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Opacity(
                                opacity: isLocked ? 0.4 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _getZoneColor(zoneCode)
                                            .withValues(alpha: 0.2),
                                        _getZoneColor(zoneCode)
                                            .withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isLocked
                                            ? Icons.lock
                                            : _getZoneIcon(zoneCode),
                                        size: 36,
                                        color: _getZoneColor(zoneCode),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        zone['name'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _getZoneColor(zoneCode),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${zone['min_hr']}-${zone['max_hr']} bpm',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        '(${zone['percent_range']})',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isCoreZone)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              if (requiresGate && !isLocked)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.verified_user,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Selected Zone Details
                  if (_selectedZone.isNotEmpty && _hrZones.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getZoneIcon(_selectedZone),
                                  color: _getZoneColor(_selectedZone),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _hrZones.firstWhere((z) =>
                                        z['zone'] == _selectedZone)['name'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_selectedZone == 'TH')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'CORE ZONE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _hrZones.firstWhere(
                                  (z) => z['zone'] == _selectedZone)['purpose'],
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getZoneColor(_selectedZone)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text(
                                        'HR Range',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${_hrZones.firstWhere((z) => z['zone'] == _selectedZone)['min_hr']}-${_hrZones.firstWhere((z) => z['zone'] == _selectedZone)['max_hr']} bpm',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _getZoneColor(_selectedZone),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        '% Max HR',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        _hrZones.firstWhere((z) =>
                                            z['zone'] == _selectedZone)['percent_range'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _getZoneColor(_selectedZone),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Start Run Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _startRun(_selectedZone),
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: Text(
                        'Start ${_hrZones.isNotEmpty ? _hrZones.firstWhere((z) => z['zone'] == _selectedZone)['name'] : ""} Run',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getZoneColor(_selectedZone),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
