import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/gps_service.dart';
import '../services/supabase_service.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  bool isTracking = false;
  bool isPaused = false;
  double distance = 0.0;
  int duration = 0;
  String pace = '--';
  List<Position> route = [];
  Timer? timer;
  StreamSubscription<Position>? positionStream;

  void _startTracking() async {
    bool hasPermission = await GPSService.requestPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Location permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      isTracking = true;
      isPaused = false;
      distance = 0.0;
      duration = 0;
      pace = '--';
      route = [];
    });

    // Start timer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        setState(() {
          duration++;
          if (distance > 0 && duration > 0) {
            double paceValue = (duration / 60) / distance;
            pace = paceValue.toStringAsFixed(2);
          }
        });
      }
    });

    // Start GPS tracking
    positionStream = GPSService.getPositionStream().listen((position) {
      if (!isPaused) {
        setState(() {
          if (route.isNotEmpty) {
            distance += GPSService.calculateDistance(
              route.last.latitude,
              route.last.longitude,
              position.latitude,
              position.longitude,
            );
          }
          route.add(position);
        });
      }
    });
  }

  void _pauseTracking() {
    setState(() {
      isPaused = true;
    });
  }

  void _resumeTracking() {
    setState(() {
      isPaused = false;
    });
  }

  void _stopTracking() {
    setState(() {
      isTracking = false;
      isPaused = false;
    });
    timer?.cancel();
    positionStream?.cancel();
  }

  Future<void> _finishAndSave() async {
    _stopTracking();

    if (distance < 0.1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Distance too short to save (minimum 0.1 km)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      await SupabaseService.saveWorkout(
        distanceKm: distance,
        durationMinutes: (duration / 60).ceil(),
        activityType: 'Run',
        gpsData: route.map((p) => {
          'lat': p.latitude,
          'lng': p.longitude,
          'timestamp': p.timestamp?.toIso8601String() ?? '',
        }).toList(),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Run saved! Distance: ${distance.toStringAsFixed(2)} km, '
              'Duration: ${(duration / 60).ceil()} min',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Reset
        setState(() {
          distance = 0.0;
          duration = 0;
          pace = '--';
          route = [];
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving run: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live GPS Tracker'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // GPS Status Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isTracking && !isPaused ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        isTracking && !isPaused ? 'GPS Tracking' : 'GPS Idle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Stats Display
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatDisplay(
                        'Distance',
                        '${distance.toStringAsFixed(2)} km',
                        Icons.straighten,
                        Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      _buildStatDisplay(
                        'Duration',
                        _formatDuration(duration),
                        Icons.timer,
                        Colors.green,
                      ),
                      const SizedBox(height: 24),
                      _buildStatDisplay(
                        'Pace',
                        '$pace min/km',
                        Icons.speed,
                        Colors.orange,
                      ),
                      const SizedBox(height: 24),
                      _buildStatDisplay(
                        'GPS Points',
                        '${route.length}',
                        Icons.location_on,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Control Buttons
                if (!isTracking)
                  _buildStartButton()
                else
                  _buildTrackingControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatDisplay(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startTracking,
        icon: const Icon(Icons.play_arrow, size: 32),
        label: const Text(
          'Start Run',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildTrackingControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isPaused ? _resumeTracking : _pauseTracking,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 24),
                label: Text(
                  isPaused ? 'Resume' : 'Pause',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaused ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _finishAndSave,
                icon: const Icon(Icons.check, size: 24),
                label: const Text(
                  'Finish',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Discard Run?'),
                  content: const Text('Are you sure you want to discard this run? All data will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _stopTracking();
                        setState(() {
                          distance = 0.0;
                          duration = 0;
                          pace = '--';
                          route = [];
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Discard', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text(
              'Discard Run',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
