// Enhanced GPS Tracker Screen
// Real-time run tracking with workout guidance and Strava sync

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/run_session.dart';
import '../services/run_session_service.dart';

class TrackerScreen extends StatefulWidget {
  final Map<String, dynamic>? workout; // Optional workout from training plan

  const TrackerScreen({super.key, this.workout});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final MapController _mapController = MapController();
  final _uuid = const Uuid();

  // State
  RunSession? _session;
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isLoadingLocation = true;
  LatLng? _currentLocation;

  // Timers
  Timer? _durationTimer;
  Timer? _gpsTimer;
  StreamSubscription<Position>? _positionStream;

  // Workout guidance
  String? _workoutType;
  String? _paceGuidance;
  Color _workoutColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initWorkoutGuidance();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _gpsTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _initWorkoutGuidance() {
    if (widget.workout != null) {
      _workoutType = widget.workout!['type'] as String?;
      _paceGuidance = widget.workout!['pace_guidance'] as String?;

      // Set color based on workout type
      switch (_workoutType?.toLowerCase()) {
        case 'interval':
          _workoutColor = Colors.orange;
          break;
        case 'tempo':
          _workoutColor = Colors.amber;
          break;
        case 'long_run':
        case 'long run':
          _workoutColor = Colors.purple;
          break;
        case 'easy':
          _workoutColor = Colors.blue;
          break;
        default:
          _workoutColor = Colors.grey;
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Please enable location services');
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController.move(_currentLocation!, 17.0);
    } catch (e) {
      developer.log('Error getting location: $e');
      _showError('Error getting location');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _startTracking() async {
    if (_currentLocation == null) {
      _showError('Getting your location...');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showError('Please login to track runs');
      return;
    }

    // Create new run session
    final now = DateTime.now();
    _session = RunSession(
      id: _uuid.v4(),
      userId: userId,
      startTime: now,
      workoutName: widget.workout?['name'] as String?,
      workoutType: _workoutType,
      plannedDistanceKm: widget.workout?['distance_km'] as double?,
      plannedPaceTarget: _paceGuidance,
      workoutContext: widget.workout, // Store full workout context
      route: [
        RoutePoint(
          latLng: _currentLocation!,
          timestamp: now,
        ),
      ],
    );

    setState(() {
      _isTracking = true;
      _isPaused = false;
    });

    // Start duration timer (1 second updates)
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _session != null) {
        setState(() {
          _session!.durationSeconds++;
          _session!.totalSeconds++;
        });
      } else if (_isPaused && _session != null) {
        _session!.totalSeconds++;
      }
    });

    // Start GPS tracking (5 second intervals for better accuracy)
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isPaused) {
        await _updatePosition();
      }
    });
  }

  Future<void> _updatePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      if (_session != null) {
        final routePoint = RoutePoint(
          latLng: newLocation,
          timestamp: DateTime.now(),
          altitude: position.altitude,
          accuracy: position.accuracy,
          speed: position.speed,
        );

        setState(() {
          _session!.addRoutePoint(routePoint);
          _currentLocation = newLocation;
        });

        // Center map on current location
        _mapController.move(newLocation, 17.0);
      }
    } catch (e) {
      developer.log('Error updating position: $e');
    }
  }

  void _pauseTracking() {
    setState(() => _isPaused = true);
    _session?.pauseIntervals.add(_session!.totalSeconds);
  }

  void _resumeTracking() {
    setState(() => _isPaused = false);
  }

  Future<void> _completeRun() async {
    if (_session == null) return;

    _durationTimer?.cancel();
    _gpsTimer?.cancel();

    _session!.complete();

    setState(() {
      _isTracking = false;
    });

    // Save to Supabase
    final saved = await RunSessionService.saveSession(_session!);

    if (!mounted) return;

    if (saved) {
      // Navigate to post-run analysis screen
      Navigator.pushReplacementNamed(
        context,
        '/run-complete',
        arguments: _session,
      );
    } else {
      _showError('Failed to save run. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double? paceMinPerKm) {
    if (paceMinPerKm == null || paceMinPerKm == 0 || paceMinPerKm.isInfinite) {
      return '--:--';
    }
    final m = paceMinPerKm.floor();
    final s = ((paceMinPerKm - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: _workoutColor,
        foregroundColor: Colors.white,
        title: Text(widget.workout?['name'] ?? 'Run Tracker'),
        actions: [
          if (_isTracking)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => _showCompleteDialog(),
            ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Workout guidance banner
                if (widget.workout != null && !_isTracking)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: _workoutColor.withOpacity(0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _workoutType?.toUpperCase() ?? 'WORKOUT',
                          style: TextStyle(
                            color: _workoutColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (_paceGuidance != null)
                          Text(
                            _paceGuidance!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        if (widget.workout!['distance_km'] != null)
                          Text(
                            'Target: ${widget.workout!['distance_km']} km',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                // Map
                Expanded(
                  flex: 2,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation ?? LatLng(51.5, -0.09),
                      initialZoom: 17.0,
                      maxZoom: 19.0,
                      minZoom: 5.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.safestride.app',
                      ),
                      // Route polyline
                      if (_session != null && _session!.route.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points:
                                  _session!.route.map((p) => p.latLng).toList(),
                              color: _workoutColor,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                      // Current location marker
                      if (_currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _workoutColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      // Start marker
                      if (_session != null && _session!.route.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _session!.route.first.latLng,
                              width: 30,
                              height: 30,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Metrics panel
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0xFF16213E),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Main metrics row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetric(
                              'Distance',
                              _session != null
                                  ? '${(_session!.distanceMeters / 1000).toStringAsFixed(2)}'
                                  : '0.00',
                              'km',
                            ),
                            _buildMetric(
                              'Duration',
                              _session != null
                                  ? _formatDuration(_session!.durationSeconds)
                                  : '0:00',
                              '',
                            ),
                            _buildMetric(
                              'Pace',
                              _session != null
                                  ? _formatPace(_session!.currentPaceMinPerKm ??
                                      _session!.avgPaceMinPerKm)
                                  : '--:--',
                              '/km',
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Control buttons
                        if (!_isTracking)
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: _startTracking,
                              icon: const Icon(Icons.play_arrow, size: 32),
                              label: const Text(
                                'Start Run',
                                style: TextStyle(fontSize: 20),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 60,
                                  child: ElevatedButton.icon(
                                    onPressed: _isPaused
                                        ? _resumeTracking
                                        : _pauseTracking,
                                    icon: Icon(
                                      _isPaused
                                          ? Icons.play_arrow
                                          : Icons.pause,
                                      size: 28,
                                    ),
                                    label: Text(
                                      _isPaused ? 'Resume' : 'Pause',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isPaused
                                          ? Colors.green
                                          : Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 80,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: () => _showCompleteDialog(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(Icons.stop, size: 28),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetric(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Complete Run?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          _session != null
              ? 'Distance: ${(_session!.distanceMeters / 1000).toStringAsFixed(2)} km\n'
                  'Duration: ${_formatDuration(_session!.durationSeconds)}\n'
                  'Pace: ${_formatPace(_session!.avgPaceMinPerKm)}/km'
              : 'Complete this run?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeRun();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
