import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:developer' as developer;

class GPSTrackerScreen extends StatefulWidget {
  const GPSTrackerScreen({super.key});

  @override
  State<GPSTrackerScreen> createState() => _GPSTrackerScreenState();
}

class _GPSTrackerScreenState extends State<GPSTrackerScreen> {
  final MapController _mapController = MapController();

  bool _isTracking = false;
  bool _isPaused = false;
  bool _isLoadingLocation = true;

  LatLng? _currentLocation;
  List<LatLng> _trackPoints = [];

  double _distance = 0.0;
  int _duration = 0;
  double _pace = 0.0;
  double _avgSpeed = 0.0;
  int _calories = 0;

  Position? _lastPosition;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  String? _selectedWorkout;
  List<Map<String, dynamic>> _todayWorkouts = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadTodayWorkouts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Move map to current location
      _mapController.move(_currentLocation!, 16.0);
    } catch (e) {
      developer.log('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadTodayWorkouts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await Supabase.instance.client
          .from('workout_calendar')
          .select(
              'id, workout_name, workout_type, duration_minutes, scheduled_date')
          .eq('user_id', userId)
          .gte('scheduled_date', startOfDay.toIso8601String())
          .lt('scheduled_date', endOfDay.toIso8601String())
          .order('scheduled_date', ascending: true);

      setState(() {
        _todayWorkouts = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      developer.log('Error loading workouts: $e');
    }
  }

  Future<void> _startTracking() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your location...')),
      );
      return;
    }

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _distance = 0.0;
      _duration = 0;
      _calories = 0;
      _trackPoints = [_currentLocation!];
      _lastPosition = null;
    });

    // Start duration timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _duration++;
          if (_duration > 0 && _distance > 0) {
            _pace = _duration / 60 / _distance; // min/km
            _avgSpeed = (_distance / _duration) * 3600; // km/h
            _calories = (_distance * 70).toInt(); // Rough estimate: 70 cal/km
          }
        });
      }
    });

    // Start position stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = newLocation;

        if (!_isPaused) {
          _trackPoints.add(newLocation);

          if (_lastPosition != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            _distance += distanceInMeters / 1000; // Convert to km
          }
          _lastPosition = position;
        }
      });

      // Auto-center map on current location
      if (_isTracking && !_isPaused) {
        _mapController.move(newLocation, _mapController.camera.zoom);
      }
    });
  }

  void _pauseTracking() {
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    _positionStream?.cancel();

    // Save to database
    await _saveActivity();

    setState(() {
      _isTracking = false;
      _isPaused = false;
    });

    if (mounted) {
      _showCompletionDialog();
    }
  }

  Future<void> _saveActivity() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Save activity and get the ID
      final activityResponse = await Supabase.instance.client
          .from('gps_activities')
          .insert({
            'user_id': userId,
            'athlete_id': userId,
            'platform': 'manual',
            'platform_activity_id':
                'manual_${DateTime.now().millisecondsSinceEpoch}',
            'activity_type': _selectedWorkout ?? 'Running',
            'distance_meters': (_distance * 1000).toInt(),
            'duration_seconds': _duration,
            'calories': _calories,
            'avg_speed': _avgSpeed,
            'start_time': DateTime.now()
                .subtract(Duration(seconds: _duration))
                .toIso8601String(),
            'end_time': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final activityId = activityResponse['id'] as String;

      // Save all track points
      if (_trackPoints.isNotEmpty) {
        final trackPointsData = _trackPoints.asMap().entries.map((entry) {
          return {
            'activity_id': activityId,
            'latitude': entry.value.latitude,
            'longitude': entry.value.longitude,
            'point_order': entry.key,
            'timestamp': DateTime.now()
                .subtract(Duration(seconds: _duration))
                .add(Duration(
                    seconds:
                        (entry.key * _duration / _trackPoints.length).round()))
                .toIso8601String(),
          };
        }).toList();

        await Supabase.instance.client
            .from('gps_track_points')
            .insert(trackPointsData);
        developer.log(
            '✅ Activity $activityId saved with ${_trackPoints.length} track points');
      }
    } catch (e) {
      developer.log('❌ Error saving activity: $e');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Workout Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogStat('Distance', '${_distance.toStringAsFixed(2)} km',
                Icons.straighten),
            const SizedBox(height: 8),
            _buildDialogStat(
                'Duration', _formatDuration(_duration), Icons.timer),
            const SizedBox(height: 8),
            _buildDialogStat('Avg Pace', _formatPace(_pace), Icons.speed),
            const SizedBox(height: 8),
            _buildDialogStat(
                'Calories', '$_calories kcal', Icons.local_fire_department),
            const SizedBox(height: 8),
            _buildDialogStat(
                'Est. VO2 Max',
                '${_calculateVO2Max().toStringAsFixed(1)} ml/kg/min',
                Icons.favorite),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _trackPoints.clear();
                _distance = 0;
                _duration = 0;
                _calories = 0;
              });
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Go to Calendar tab → Select today → View your workout analysis!'),
                  duration: Duration(seconds: 4),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('View Full Analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showWorkoutSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Today\'s Workout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_todayWorkouts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No scheduled workouts for today',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_todayWorkouts.map((workout) {
                return ListTile(
                  leading: const Icon(Icons.fitness_center,
                      color: Colors.deepPurple),
                  title: Text(workout['workout_name'] ?? 'Workout'),
                  subtitle: Text(
                    '${workout['workout_type']} • ${workout['duration_minutes']} min',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      _selectedWorkout = workout['workout_name'];
                    });
                    Navigator.pop(context);
                    _startTracking();
                  },
                );
              })),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.add_circle_outline, color: Colors.green),
              title: const Text('Free Run (No Workout)'),
              onTap: () {
                setState(() {
                  _selectedWorkout = 'Free Run';
                });
                Navigator.pop(context);
                _startTracking();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map View
          _isLoadingLocation
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Getting your location...'),
                    ],
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _currentLocation ?? const LatLng(51.5, -0.09),
                    initialZoom: 16.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.akura.safestride',
                    ),
                    // Track polyline
                    if (_trackPoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _trackPoints,
                            color: Colors.deepPurple,
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
                                color: Colors.blue.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.blue, width: 3),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.navigation,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

          // Top bar with workout info
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedWorkout ?? 'GPS Tracker',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isTracking)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isPaused
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isPaused ? Colors.orange : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isPaused ? 'Paused' : 'Live',
                            style: TextStyle(
                              color: _isPaused ? Colors.orange : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Center location button
          if (!_isTracking)
            Positioned(
              top: 100,
              right: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 16.0);
                  }
                },
                child: const Icon(Icons.my_location, color: Colors.deepPurple),
              ),
            ),

          // Bottom stats and controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stats Grid
                    if (_isTracking)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatCard(
                                icon: Icons.straighten,
                                value: _distance.toStringAsFixed(2),
                                unit: 'km',
                                label: 'Distance',
                              ),
                              _StatCard(
                                icon: Icons.timer,
                                value: _formatDuration(_duration),
                                unit: '',
                                label: 'Time',
                              ),
                              _StatCard(
                                icon: Icons.speed,
                                value:
                                    _pace > 0 ? _pace.toStringAsFixed(1) : '--',
                                unit: 'min/km',
                                label: 'Pace',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatCard(
                                icon: Icons.trending_up,
                                value: _avgSpeed.toStringAsFixed(1),
                                unit: 'km/h',
                                label: 'Avg Speed',
                              ),
                              _StatCard(
                                icon: Icons.local_fire_department,
                                value: '$_calories',
                                unit: 'kcal',
                                label: 'Calories',
                              ),
                              _StatCard(
                                icon: Icons.route,
                                value: '${_trackPoints.length}',
                                unit: 'pts',
                                label: 'GPS Points',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Action Buttons
                    if (!_isTracking)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _todayWorkouts.isEmpty
                              ? _startTracking
                              : _showWorkoutSelector,
                          icon: const Icon(Icons.play_arrow, size: 28),
                          label: const Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _pauseTracking,
                                icon: Icon(
                                  _isPaused ? Icons.play_arrow : Icons.pause,
                                  size: 24,
                                ),
                                label: Text(
                                  _isPaused ? 'Resume' : 'Pause',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _stopTracking,
                                icon: const Icon(Icons.stop, size: 24),
                                label: const Text(
                                  'Finish',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _formatPace(double pace) {
    if (pace <= 0) return '--';
    return pace.toStringAsFixed(2);
  }

  double _calculateVO2Max() {
    if (_avgSpeed <= 0) return 40.0;
    final vo2max = (15 + (_avgSpeed * 3)) * 0.9;
    return vo2max.clamp(30.0, 85.0);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.deepPurple),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
