// Post-Run Analysis Screen
// Displays completed run stats, splits, route map, and Strava upload

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/run_session.dart';
import '../models/workout_completion.dart';
import '../services/run_session_service.dart';
import 'dart:developer' as developer;

class RunCompleteScreen extends StatefulWidget {
  final RunSession session;

  const RunCompleteScreen({super.key, required this.session});

  @override
  State<RunCompleteScreen> createState() => _RunCompleteScreenState();
}

class _RunCompleteScreenState extends State<RunCompleteScreen> {
  final _supabase = Supabase.instance.client;
  bool _isUploading = false;
  bool _uploadSuccess = false;
  String? _uploadMessage;

  @override
  void initState() {
    super.initState();
    _recordWorkoutCompletion();
  }

  Future<void> _recordWorkoutCompletion() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final session = widget.session;
      final workoutContext = session.workoutContext;

      // Create workout completion record
      final completion = WorkoutCompletion(
        id: const Uuid().v4(),
        userId: userId,
        runSessionId: session.id,
        completedAt: session.endTime ?? DateTime.now(),
        workoutName: session.workoutName ?? 'Free Run',
        workoutType: session.workoutType,
        plannedDistanceKm:
            workoutContext?['distance_km'] ?? session.distanceMeters / 1000,
        actualDistanceKm: session.distanceMeters / 1000,
        plannedDurationSec: 0, // Not tracked for now
        actualDurationSec: session.durationSeconds,
        plannedPaceGuide: workoutContext?['pace_guidance'],
        actualPaceMinPerKm: session.avgPaceMinPerKm,
        weekNumber: workoutContext?['week_number'],
        trainingPlanGoal: workoutContext?['training_plan_goal'],
        isOnPlan: workoutContext != null,
      );

      await WorkoutCompletionService.recordCompletion(completion);
      developer.log('Workout completion recorded: ${completion.id}');
    } catch (e) {
      developer.log('Error recording workout completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final distanceKm = session.distanceMeters / 1000;
    final paceFormatted = RunSessionService.formatPace(session.avgPaceMinPerKm);
    final durationFormatted =
        RunSessionService.formatDuration(session.durationSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00D9A3),
        foregroundColor: Colors.white,
        title: const Text('Run Complete! 🎉'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/strava-home'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Celebration banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D9A3),
                    const Color(0xFF00D9A3).withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session.workoutName ?? 'Great Run!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (session.workoutType != null)
                    Text(
                      session.workoutType!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                ],
              ),
            ),

            // Key stats cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Distance',
                      '${distanceKm.toStringAsFixed(2)}',
                      'km',
                      Icons.straighten,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Duration',
                      durationFormatted,
                      '',
                      Icons.timer,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Avg Pace',
                      paceFormatted.split('/').first,
                      '/km',
                      Icons.speed,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ),

            // Additional metrics
            if (session.maxSpeedKmh != null ||
                session.calories != null ||
                session.pauseIntervals.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (session.maxSpeedKmh != null)
                      _buildMiniStat(
                        'Max Speed',
                        '${session.maxSpeedKmh!.toStringAsFixed(1)} km/h',
                        Icons.flash_on,
                      ),
                    if (session.calories != null)
                      _buildMiniStat(
                        'Calories',
                        '${session.calories}',
                        Icons.local_fire_department,
                      ),
                    if (session.pauseIntervals.isNotEmpty)
                      _buildMiniStat(
                        'Pauses',
                        '${session.pauseIntervals.length}',
                        Icons.pause_circle,
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Splits section
            if (session.splits.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.splitscreen,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Splits',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white12),
                        ),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 40,
                            child: Text(
                              'KM',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'TIME',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'PACE',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Splits data
                    ...session.splits
                        .map((split) => _buildSplitRow(split, session)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Route map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              clipBehavior: Clip.antiAlias,
              child: session.route.length > 1
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: session.route.first.latLng,
                        initialZoom: 15.0,
                        interactiveFlags: InteractiveFlag.all,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.safestride.app',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points:
                                  session.route.map((p) => p.latLng).toList(),
                              color: const Color(0xFF00D9A3),
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // Start marker
                            Marker(
                              point: session.route.first.latLng,
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
                            // End marker
                            Marker(
                              point: session.route.last.latLng,
                              width: 30,
                              height: 30,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sports_score,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        'No route data available',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Upload to Strava button
                  if (!session.isUploaded)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadToStrava,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload, size: 24),
                        label: Text(
                          _isUploading ? 'Uploading...' : 'Upload to Strava',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC4C02),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Uploaded to Strava',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Upload status message
                  if (_uploadMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _uploadMessage!,
                      style: TextStyle(
                        color: _uploadSuccess ? Colors.green : Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Done button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, '/strava-home'),
                      icon: const Icon(Icons.home),
                      label: const Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitRow(SplitData split, RunSession session) {
    final avgPace = session.avgPaceMinPerKm ?? 0;
    final splitPace = split.avgPaceMinPerKm;
    final isFasterThanAvg = splitPace < avgPace && avgPace > 0;
    final isSlowerThanAvg = splitPace > avgPace && avgPace > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${split.distanceKm}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              split.durationFormatted,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  split.paceFormatted,
                  style: TextStyle(
                    color: isFasterThanAvg
                        ? Colors.green
                        : isSlowerThanAvg
                            ? Colors.orange
                            : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                if (isFasterThanAvg)
                  const Icon(Icons.arrow_upward, color: Colors.green, size: 16)
                else if (isSlowerThanAvg)
                  const Icon(Icons.arrow_downward,
                      color: Colors.orange, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadToStrava() async {
    setState(() {
      _isUploading = true;
      _uploadMessage = null;
    });

    try {
      final result = await RunSessionService.uploadToStrava(widget.session);

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadSuccess = result?['success'] ?? false;
        _uploadMessage = result?['message'] ?? 'Upload completed';
      });

      if (_uploadSuccess) {
        // Update session status
        widget.session.isUploaded = true;
        widget.session.stravaActivityId = result?['strava_activity_id'];
      }
    } catch (e) {
      developer.log('Upload error: $e');
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadSuccess = false;
        _uploadMessage = 'Upload failed. Please try again.';
      });
    }
  }
}
