import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_calendar_entry.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/workout_detail_screen.dart';
import '../services/gps_data_fetcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:developer' as developer;

class GPSActivityTabs extends StatefulWidget {
  final Map<String, dynamic> activity;
  final WorkoutCalendarEntry workout;

  const GPSActivityTabs({
    super.key,
    required this.activity,
    required this.workout,
  });

  @override
  State<GPSActivityTabs> createState() => _GPSActivityTabsState();
}

class _GPSActivityTabsState extends State<GPSActivityTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>>? _actualSplits;
  Map<String, dynamic>? _physiologicalAnalysis;
  List<LatLng> _routePoints = [];
  LatLng? _centerLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActualData();
    _loadRouteData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActualData() async {
    try {
      // Try to fetch actual split data from Strava activity streams
      final activityId = widget.activity['strava_activity_id'];

      if (activityId != null) {
        // Fetch splits from database if available
        final response = await Supabase.instance.client
            .from('activity_splits')
            .select()
            .eq('activity_id', activityId)
            .order('split_number');

        if (response.isNotEmpty) {
          _actualSplits = List<Map<String, dynamic>>.from(response);
        }
      }

      // Calculate physiological metrics
      _physiologicalAnalysis = _calculatePhysiologicalMetrics();

      setState(() {});
    } catch (e) {
      developer.log('Error loading actual split data: $e');
      setState(() {});
    }
  }

  Future<void> _loadRouteData() async {
    try {
      final activityId = widget.activity['id'];
      if (activityId == null) return;

      // Fetch GPS track points from database
      final response = await Supabase.instance.client
          .from('gps_track_points')
          .select('latitude, longitude')
          .eq('activity_id', activityId)
          .order('timestamp', ascending: true);

      if (response.isNotEmpty) {
        final points = (response as List).map((point) {
          return LatLng(
            (point['latitude'] as num).toDouble(),
            (point['longitude'] as num).toDouble(),
          );
        }).toList();

        if (points.isNotEmpty) {
          // Calculate center point
          double lat =
              points.fold(0.0, (sum, p) => sum + p.latitude) / points.length;
          double lng =
              points.fold(0.0, (sum, p) => sum + p.longitude) / points.length;

          setState(() {
            _routePoints = points;
            _centerLocation = LatLng(lat, lng);
          });
        }
      } else {
        // If no track points in database, try to create a simple route based on start/end locations
        final startLat = widget.activity['start_latitude'] as num?;
        final startLng = widget.activity['start_longitude'] as num?;
        final endLat = widget.activity['end_latitude'] as num?;
        final endLng = widget.activity['end_longitude'] as num?;

        if (startLat != null && startLng != null) {
          final startPoint = LatLng(startLat.toDouble(), startLng.toDouble());
          final endPoint = (endLat != null && endLng != null)
              ? LatLng(endLat.toDouble(), endLng.toDouble())
              : startPoint;

          setState(() {
            _routePoints = [startPoint, endPoint];
            _centerLocation = startPoint;
          });
        }
      }
    } catch (e) {
      developer.log('Error loading route data: $e');
    }
  }

  Map<String, dynamic> _calculatePhysiologicalMetrics() {
    final avgHR = widget.activity['avg_heart_rate'] as num?;
    final maxHR = widget.activity['max_heart_rate'] as num?;
    final durationMin = (widget.activity['duration_seconds'] as int) / 60;
    final distanceKm = (widget.activity['distance_meters'] as num) / 1000;
    final avgPace = widget.activity['avg_pace'] as num?;
    final calories = widget.activity['calories'] as int?;
    final avgCadence = widget.activity['avg_cadence'] as num?;
    final avgStrideLength = widget.activity['avg_stride_length'] as num?;
    final avgGCT = widget.activity['avg_ground_contact_time'] as num?;

    // Estimate VO2max and aerobic capacity
    double? vo2max;
    double? cardiacOutput;
    double? metabolicEfficiency;
    String? fitnessLevel;
    List<String> coachingRecommendations = [];

    if (avgHR != null && avgPace != null) {
      // VO2max estimation using HR and pace
      // VO2max (ml/kg/min) = 15.3 × (MHR/RHR)
      // Simplified: Higher pace at lower HR = better VO2max
      final paceSpeed = 60 / avgPace; // km/h
      vo2max = (15 + (paceSpeed * 3)) * (1 - (avgHR - 120) / 200);
      vo2max = vo2max.clamp(30.0, 85.0);

      // Cardiac output estimation (L/min) = Stroke Volume × Heart Rate
      // Assuming avg SV of 70-120ml for trained runners
      final estimatedSV = 70 + (vo2max - 30) * 0.5; // ml
      cardiacOutput = (estimatedSV * avgHR) / 1000; // L/min

      // Metabolic efficiency (calories per km)
      if (calories != null && distanceKm > 0) {
        metabolicEfficiency = calories / distanceKm;
      }

      // Fitness level assessment
      if (vo2max >= 55) {
        fitnessLevel = 'Excellent - Elite athlete level';
      } else if (vo2max >= 45) {
        fitnessLevel = 'Good - Well-trained runner';
      } else if (vo2max >= 35) {
        fitnessLevel = 'Average - Recreational runner';
      } else {
        fitnessLevel = 'Below Average - Needs improvement';
      }
    }

    // HR Zone Analysis
    String? hrZone;
    double? hrPercentage;
    if (avgHR != null && maxHR != null) {
      hrPercentage = (avgHR / maxHR) * 100;
      if (hrPercentage < 60) {
        hrZone = 'Zone 1 - Easy/Recovery';
      } else if (hrPercentage < 70) {
        hrZone = 'Zone 2 - Aerobic Base';
      } else if (hrPercentage < 80) {
        hrZone = 'Zone 3 - Tempo';
      } else if (hrPercentage < 90) {
        hrZone = 'Zone 4 - Threshold';
      } else {
        hrZone = 'Zone 5 - VO2max/Anaerobic';
      }
    }

    // Running Economy Analysis
    bool isEconomical = true;
    if (avgCadence != null) {
      if (avgCadence < 160 || avgCadence > 190) {
        isEconomical = false;
        coachingRecommendations.add(
            'Cadence: ${avgCadence.round()} spm is outside optimal range (170-180 spm). '
            'Protocol: Practice metronome drills at 180 bpm, focus on quick ground contact.');
      }
    }

    if (avgStrideLength != null) {
      // Optimal stride length varies, but generally 1.0-1.3m for endurance
      if (avgStrideLength < 0.9 || avgStrideLength > 1.4) {
        isEconomical = false;
        coachingRecommendations.add(
            'Stride Length: ${avgStrideLength.toStringAsFixed(2)}m may be inefficient. '
            'Protocol: Work on hip mobility and power through plyometric drills.');
      }
    }

    if (avgGCT != null) {
      // Ground contact time should be <250ms for efficient running
      if (avgGCT > 250) {
        isEconomical = false;
        coachingRecommendations.add(
            'Ground Contact Time: ${avgGCT.round()}ms is high (optimal <250ms). '
            'Protocol: Barefoot running drills, focus on forefoot landing, increase cadence.');
      }
    }

    // HR-based recommendations
    if (hrPercentage != null) {
      if (hrPercentage > 85 && durationMin > 45) {
        coachingRecommendations.add(
            'Training Load: High intensity (${hrPercentage.round()}% max HR) sustained for ${durationMin.round()} min. '
            'Protocol: Ensure 48-72 hours recovery. Monitor for overtraining signs.');
      }

      if (hrPercentage < 65 && avgPace! > 7.0) {
        coachingRecommendations.add(
            'Aerobic Development: Low intensity detected. Good for base building. '
            'Protocol: Maintain 60-70% max HR for optimal mitochondrial density gains.');
      }
    }

    // Mitochondrial density improvement indicators
    String? mitochondrialStatus;
    if (hrPercentage != null && hrPercentage >= 60 && hrPercentage <= 75) {
      mitochondrialStatus =
          'Optimal zone for mitochondrial biogenesis (Zone 2-3). '
          'This intensity stimulates mitochondrial density increase, improving fat oxidation.';
    } else if (hrPercentage != null && hrPercentage > 80) {
      mitochondrialStatus = 'High intensity limits mitochondrial adaptations. '
          'This session focuses more on glycolytic capacity and VO2max.';
    }

    // Overall fitness recommendations
    if (!isEconomical) {
      coachingRecommendations.add(
          'Running Economy: Biomechanics need attention. Prioritize form work over volume.');
    }

    if (vo2max != null && vo2max < 45) {
      coachingRecommendations.add(
          'VO2max: Current estimate ${vo2max.toStringAsFixed(1)} ml/kg/min. '
          'Protocol: Add 1-2 interval sessions per week (4-6 x 800m at 5K pace with equal rest).');
    }

    return {
      'vo2max': vo2max,
      'cardiacOutput': cardiacOutput,
      'metabolicEfficiency': metabolicEfficiency,
      'fitnessLevel': fitnessLevel,
      'hrZone': hrZone,
      'hrPercentage': hrPercentage,
      'isEconomical': isEconomical,
      'mitochondrialStatus': mitochondrialStatus,
      'coachingRecommendations': coachingRecommendations,
    };
  }

  List<Map<String, dynamic>> _generateSplits() {
    // Use actual splits if available, otherwise estimate from summary data
    if (_actualSplits != null && _actualSplits!.isNotEmpty) {
      return _actualSplits!;
    }

    // If no actual splits, create realistic estimates based on activity profile
    final distanceKm = (widget.activity['distance_meters'] as num) / 1000;
    final durationSec = widget.activity['duration_seconds'] as int;
    final avgHR = widget.activity['avg_heart_rate'] as num?;
    final elevGain = widget.activity['elevation_gain'] as num? ?? 0;

    final numSplits = distanceKm.ceil();
    final splits = <Map<String, dynamic>>[];

    final avgTimePerKm = durationSec / distanceKm;
    int cumulativeTime = 0;

    // Generate more realistic variations based on elevation and fatigue
    final elevPerKm = elevGain / distanceKm;

    for (int i = 0; i < numSplits; i++) {
      final isLastSplit = i == numSplits - 1;
      final splitDistance = isLastSplit ? distanceKm - i : 1.0;

      // Realistic pace variation factors:
      // 1. Warm-up effect (slower start)
      // 2. Elevation impact
      // 3. Fatigue accumulation (slower end)
      // 4. Natural variation

      double paceModifier = 1.0;

      // Warm-up effect (first 2 km slower by 5-15%)
      if (i == 0) {
        paceModifier *= 1.12;
      } else if (i == 1) {
        paceModifier *= 1.05;
      }

      // Fatigue effect (last 20% of run slower by 3-8%)
      if (i / numSplits > 0.8) {
        paceModifier *= 1.05;
      }

      // Natural variation (±3%)
      paceModifier *= 0.97 + (math.sin(i * 1.3) + 1) * 0.03;

      // Elevation impact (steeper sections slower)
      if (elevPerKm > 10) {
        final elevImpact = (i % 3 == 0) ? 1.08 : 0.98; // Simulate hills
        paceModifier *= elevImpact;
      }

      final splitTime = (avgTimePerKm * splitDistance * paceModifier).round();
      final splitPace = splitTime / splitDistance / 60; // min/km

      cumulativeTime += splitTime;

      // HR variation based on pace and cumulative fatigue
      int? hrForSplit;
      if (avgHR != null) {
        // HR increases with effort and fatigue
        final fatigueEffect = (i / numSplits) * 8; // Up to +8 bpm from fatigue
        final paceEffect = (paceModifier - 1) * 15; // Faster pace = higher HR
        final naturalVar = math.sin(i * 0.9) * 3; // Natural variation

        hrForSplit = (avgHR + fatigueEffect + paceEffect + naturalVar).round();
        hrForSplit = hrForSplit.clamp(avgHR - 10, avgHR + 15).toInt();
      }

      splits.add({
        'split': i + 1,
        'distance': splitDistance,
        'time': splitTime,
        'cumulativeTime': cumulativeTime,
        'pace': splitPace,
        'avgHR': hrForSplit,
        'elevation':
            elevPerKm > 0 ? (elevPerKm * (1 + math.sin(i * 0.7))).round() : 0,
      });
    }

    return splits;
  }

  void _openWorkoutDetailScreen(BuildContext context) {
    // Get the activity ID from the activity data
    final activityId = widget.activity['platform_activity_id']?.toString() ??
        widget.activity['strava_activity_id']?.toString() ??
        widget.activity['id']?.toString();

    if (activityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity ID not found')),
      );
      return;
    }

    // Determine platform
    final platformStr = widget.activity['platform'] as String?;
    GPSPlatform platform = GPSPlatform.strava;
    if (platformStr != null) {
      try {
        platform = GPSPlatform.values.firstWhere(
          (p) => p.name.toLowerCase() == platformStr.toLowerCase(),
        );
      } catch (_) {}
    }

    // Close bottom sheet and navigate to detail screen
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          activityId: activityId,
          platform: platform,
          initialData: widget.activity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = (widget.activity['distance_meters'] as num) / 1000;
    final durationSec = widget.activity['duration_seconds'] as int;

    return Column(
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.directions_run, size: 28, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workout.workout.workoutName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('EEE, MMM d • h:mm a')
                          .format(widget.workout.scheduledDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text('Completed',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // View Analysis Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openWorkoutDetailScreen(context),
              icon: const Icon(Icons.analytics, size: 18),
              label: const Text('View Full Analysis & Graphs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Splits'),
              Tab(text: 'Charts'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildSplitsTab(_generateSplits(), distanceKm, durationSec),
              _buildChartsTab(_generateSplits()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final distanceKm = (widget.activity['distance_meters'] as num) / 1000;
    final durationSec = widget.activity['duration_seconds'] as int;
    final durationMin = durationSec / 60;
    final avgPace = widget.activity['avg_pace'] as num?;
    final avgHR = widget.activity['avg_heart_rate'] as num?;
    final maxHR = widget.activity['max_heart_rate'] as num?;
    final avgCadence = widget.activity['avg_cadence'] as num?;
    final maxCadence = widget.activity['max_cadence'] as num?;
    final elevGain = widget.activity['elevation_gain'] as num?;
    final calories = widget.activity['calories'] as int?;
    final avgStrideLength = widget.activity['avg_stride_length'] as num?;
    final avgGroundContactTime =
        widget.activity['avg_ground_contact_time'] as num?;
    final avgVerticalOscillation =
        widget.activity['avg_vertical_oscillation'] as num?;
    final maxSpeed = widget.activity['max_speed'] as num?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Map
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.hardEdge,
            child: _routePoints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Route Map',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text('${distanceKm.toStringAsFixed(2)} km route',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('GPS data not available',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: _centerLocation ?? const LatLng(0, 0),
                          initialZoom: 14.0,
                          minZoom: 3.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.akura.safestride',
                          ),
                          if (_routePoints.length > 1)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePoints,
                                  color: Colors.deepPurple,
                                  strokeWidth: 4.0,
                                ),
                              ],
                            ),
                          // Start and End markers
                          if (_routePoints.isNotEmpty)
                            MarkerLayer(
                              markers: [
                                // Start marker (green)
                                Marker(
                                  point: _routePoints.first,
                                  width: 30,
                                  height: 30,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.play_arrow,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                                // End marker (red)
                                if (_routePoints.length > 1)
                                  Marker(
                                    point: _routePoints.last,
                                    width: 30,
                                    height: 30,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.stop,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      // Info overlay
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4)
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.route,
                                  size: 16, color: Colors.deepPurple),
                              const SizedBox(width: 6),
                              Text(
                                '${distanceKm.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Key Metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.blue.withValues(alpha: 0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildMetricCard(
                            'Distance',
                            '${distanceKm.toStringAsFixed(2)} km',
                            Icons.straighten,
                            Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMetricCard(
                            'Time',
                            '${durationMin.floor()}:${(durationSec % 60).toString().padLeft(2, '0')}',
                            Icons.timer,
                            Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildMetricCard(
                            'Avg Pace',
                            avgPace != null
                                ? '${avgPace.toStringAsFixed(2)} /km'
                                : '-',
                            Icons.speed,
                            Colors.purple)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMetricCard(
                            'Elevation',
                            elevGain != null ? '${elevGain.round()} m' : '-',
                            Icons.terrain,
                            Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Heart Rate
          if (avgHR != null) ...[
            Row(
              children: [
                const Text('💗', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text('Heart Rate',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Average',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('${avgHR.round()} bpm',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    ),
                  ),
                  if (maxHR != null) ...[
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Maximum',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('${maxHR.round()} bpm',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Cadence
          if (avgCadence != null) ...[
            Row(
              children: [
                const Text('👟', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text('Cadence',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Average',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('${avgCadence.round()} spm',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ],
                    ),
                  ),
                  if (maxCadence != null) ...[
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Maximum',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('${maxCadence.round()} spm',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Advanced Biomechanics
          if (avgStrideLength != null ||
              avgGroundContactTime != null ||
              avgVerticalOscillation != null) ...[
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text('Advanced Biomechanics',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  if (avgStrideLength != null)
                    _buildDetailRow(
                        'Stride Length',
                        '${avgStrideLength.toStringAsFixed(2)} m',
                        Icons.height),
                  if (avgGroundContactTime != null)
                    _buildDetailRow(
                        'Ground Contact',
                        '${avgGroundContactTime.round()} ms',
                        Icons.timer_outlined),
                  if (avgVerticalOscillation != null)
                    _buildDetailRow(
                        'Vertical Osc.',
                        '${avgVerticalOscillation.toStringAsFixed(1)} cm',
                        Icons.swap_vert),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Additional Metrics
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Additional Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                if (maxSpeed != null)
                  _buildDetailRow('Max Speed',
                      '${maxSpeed.toStringAsFixed(2)} km/h', Icons.flash_on),
                if (calories != null)
                  _buildDetailRow('Calories', '$calories kcal',
                      Icons.local_fire_department),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSplitsTab(
      List<Map<String, dynamic>> splits, double distanceKm, int durationSec) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pace Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Pace Chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Y-axis labels
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(5, (i) {
                          final pace = 5.0 + (i * 2); // 5-13 min/km
                          return Text(
                            "${pace.toStringAsFixed(0)}'",
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          );
                        }).reversed.toList(),
                      ),
                      const SizedBox(width: 8),

                      // Bars
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: splits.map((split) {
                            final pace = split['pace'] as double;
                            final maxPace = splits
                                .map((s) => s['pace'] as double)
                                .reduce(math.max);
                            final height = (pace / maxPace) * 150;

                            return Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.orange,
                                      Colors.orange.withValues(alpha: 0.6)
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                                height: height,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // X-axis
                Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: splits.map((split) {
                          return Text(
                            'KM${split['split']}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Splits Table
          const Text('Splits Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                          width: 40,
                          child: Text('KM',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                      const Expanded(
                          child: Text('Time',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                      const Expanded(
                          child: Text('Pace',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                      SizedBox(
                          width: 60,
                          child: Text('Avg HR',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),

                // Rows
                ...splits.asMap().entries.map((entry) {
                  final i = entry.key;
                  final split = entry.value;
                  final splitNum = split['split'];
                  final time = split['time'] as int;
                  final cumulativeTime = split['cumulativeTime'] as int;
                  final pace = split['pace'] as double;
                  final hr = split['avgHR'];

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: i % 2 == 0 ? Colors.grey[50] : Colors.white,
                      border:
                          Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$splitNum',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(time ~/ 60).toString().padLeft(2, '0')}:${(time % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${(cumulativeTime ~/ 60)}:${(cumulativeTime % 60).toString().padLeft(2, '0')} total',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${pace.toStringAsFixed(2)}' /km",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: hr != null
                              ? Text('$hr bpm',
                                  style: const TextStyle(fontSize: 14))
                              : const Text('-', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab(List<Map<String, dynamic>> splits) {
    final avgHR = widget.activity['avg_heart_rate'] as num?;
    final maxHR = widget.activity['max_heart_rate'] as num?;
    final analysis = _physiologicalAnalysis ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Physiological Analysis Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.purple.withValues(alpha: 0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.science, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text('Physiological Analysis',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                if (analysis['fitnessLevel'] != null) ...[
                  _buildAnalysisRow('Fitness Level', analysis['fitnessLevel'],
                      Icons.fitness_center),
                  const SizedBox(height: 8),
                ],
                if (analysis['vo2max'] != null) ...[
                  _buildAnalysisRow(
                      'VO2max Estimate',
                      '${(analysis['vo2max'] as double).toStringAsFixed(1)} ml/kg/min',
                      Icons.air),
                  const SizedBox(height: 8),
                ],
                if (analysis['cardiacOutput'] != null) ...[
                  _buildAnalysisRow(
                      'Cardiac Output',
                      '${(analysis['cardiacOutput'] as double).toStringAsFixed(1)} L/min',
                      Icons.favorite),
                  const SizedBox(height: 8),
                ],
                if (analysis['hrZone'] != null) ...[
                  _buildAnalysisRow('Heart Rate Zone', analysis['hrZone'],
                      Icons.monitor_heart),
                  const SizedBox(height: 8),
                ],
                if (analysis['metabolicEfficiency'] != null) ...[
                  _buildAnalysisRow(
                      'Metabolic Efficiency',
                      '${(analysis['metabolicEfficiency'] as double).toStringAsFixed(1)} kcal/km',
                      Icons.local_fire_department),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Mitochondrial Status
          if (analysis['mitochondrialStatus'] != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.biotech, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Mitochondrial Adaptation',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis['mitochondrialStatus'],
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Pace Chart with detailed points
          const Text('Pace Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Average',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          (splits
                                      .map((s) => s['pace'] as double)
                                      .reduce((a, b) => a + b) /
                                  splits.length)
                              .toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple),
                        ),
                        const Text('min/km',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Best Split',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          splits
                              .map((s) => s['pace'] as double)
                              .reduce((a, b) => a < b ? a : b)
                              .toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                        const Text('min/km',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                Expanded(
                  child: CustomPaint(
                    painter: DetailedPaceChartPainter(splits),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // HR Chart with zones
          if (avgHR != null) ...[
            const Text('Heart Rate Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Average',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('${avgHR.round()} bpm',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ],
                        ),
                      ),
                      if (maxHR != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Maximum',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              Text('${maxHR.round()} bpm',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                            ],
                          ),
                        ),
                      if (analysis['hrPercentage'] != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Intensity',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  '${(analysis['hrPercentage'] as double).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (analysis['hrPercentage'] as double) >
                                                  85
                                              ? Colors.orange
                                              : Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: CustomPaint(
                      painter:
                          DetailedHRChartPainter(splits, maxHR?.toDouble()),
                      child: Container(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Running Economy Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (analysis['isEconomical'] == true)
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (analysis['isEconomical'] == true)
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  (analysis['isEconomical'] == true)
                      ? Icons.check_circle
                      : Icons.warning,
                  color: (analysis['isEconomical'] == true)
                      ? Colors.green
                      : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (analysis['isEconomical'] == true)
                            ? 'Running Economy: Optimal'
                            : 'Running Economy: Needs Attention',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: (analysis['isEconomical'] == true)
                              ? Colors.green[900]
                              : Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (analysis['isEconomical'] == true)
                            ? 'Biomechanics within optimal ranges'
                            : 'See recommendations below for improvements',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Coaching Recommendations
          if (analysis['coachingRecommendations'] != null &&
              (analysis['coachingRecommendations'] as List).isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.1),
                    Colors.red.withValues(alpha: 0.1)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sports, color: Colors.orange, size: 24),
                      SizedBox(width: 8),
                      Text('Coaching Recommendations',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...(analysis['coachingRecommendations'] as List)
                      .asMap()
                      .entries
                      .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }
}

class PaceChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> splits;

  PaceChartPainter(this.splits);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final linePath = Path();

    final maxPace = splits.map((s) => s['pace'] as double).reduce(math.max);
    final minPace = splits.map((s) => s['pace'] as double).reduce(math.min);

    for (int i = 0; i < splits.length; i++) {
      final x = (i / (splits.length - 1)) * size.width;
      final pace = splits[i]['pace'] as double;
      final y =
          size.height - ((pace - minPace) / (maxPace - minPace)) * size.height;

      if (i == 0) {
        path.moveTo(x, size.height);
        path.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HRChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> splits;

  HRChartPainter(this.splits);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final linePath = Path();

    final hrValues = splits
        .map((s) => s['avgHR'] as int?)
        .where((hr) => hr != null)
        .map((hr) => hr!.toDouble())
        .toList();
    if (hrValues.isEmpty) return;

    final maxHR = hrValues.reduce(math.max);
    final minHR = hrValues.reduce(math.min);

    for (int i = 0; i < splits.length; i++) {
      final hr = splits[i]['avgHR'];
      if (hr == null) continue;

      final x = (i / (splits.length - 1)) * size.width;
      final y = size.height - ((hr - minHR) / (maxHR - minHR)) * size.height;

      if (i == 0) {
        path.moveTo(x, size.height);
        path.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Detailed Pace Chart with grid lines and data points
class DetailedPaceChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> splits;

  DetailedPaceChartPainter(this.splits);

  @override
  void paint(Canvas canvas, Size size) {
    if (splits.isEmpty) return;

    final maxPace = splits.map((s) => s['pace'] as double).reduce(math.max);
    final minPace = splits.map((s) => s['pace'] as double).reduce(math.min);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw area fill with gradient
    final areaPath = Path();
    areaPath.moveTo(0, size.height);

    for (int i = 0; i < splits.length; i++) {
      final x = (i / (splits.length - 1)) * size.width;
      final pace = splits[i]['pace'] as double;
      final y =
          size.height - ((pace - minPace) / (maxPace - minPace)) * size.height;
      areaPath.lineTo(x, y);
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.purple.withValues(alpha: 0.3),
          Colors.purple.withValues(alpha: 0.05)
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);

    // Draw line
    final linePath = Path();
    for (int i = 0; i < splits.length; i++) {
      final x = (i / (splits.length - 1)) * size.width;
      final pace = splits[i]['pace'] as double;
      final y =
          size.height - ((pace - minPace) / (maxPace - minPace)) * size.height;

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw data points
    for (int i = 0; i < splits.length; i++) {
      final x = (i / (splits.length - 1)) * size.width;
      final pace = splits[i]['pace'] as double;
      final y =
          size.height - ((pace - minPace) / (maxPace - minPace)) * size.height;

      canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = Colors.purple);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Detailed HR Chart with zones
class DetailedHRChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> splits;
  final double? maxHR;

  DetailedHRChartPainter(this.splits, this.maxHR);

  @override
  void paint(Canvas canvas, Size size) {
    final hrValues = splits
        .map((s) => s['avgHR'] as int?)
        .where((hr) => hr != null)
        .map((hr) => hr!.toDouble())
        .toList();
    if (hrValues.isEmpty) return;

    final hrMax = hrValues.reduce(math.max);
    final hrMin = hrValues.reduce(math.min);

    // Draw grid
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = Colors.grey.withValues(alpha: 0.2)
            ..strokeWidth = 1);
    }

    // Draw area
    final areaPath = Path();
    areaPath.moveTo(0, size.height);
    int validIndex = 0;
    for (int i = 0; i < splits.length; i++) {
      final hr = splits[i]['avgHR'];
      if (hr == null) continue;
      final x = (validIndex / (hrValues.length - 1)) * size.width;
      final y = size.height - ((hr - hrMin) / (hrMax - hrMin)) * size.height;
      areaPath.lineTo(x, y);
      validIndex++;
    }
    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    canvas.drawPath(
        areaPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.withValues(alpha: 0.3),
              Colors.red.withValues(alpha: 0.05)
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Draw line and points
    final linePath = Path();
    validIndex = 0;
    for (int i = 0; i < splits.length; i++) {
      final hr = splits[i]['avgHR'];
      if (hr == null) continue;
      final x = (validIndex / (hrValues.length - 1)) * size.width;
      final y = size.height - ((hr - hrMin) / (hrMax - hrMin)) * size.height;
      if (validIndex == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = Colors.red);
      validIndex++;
    }
    canvas.drawPath(
        linePath,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
