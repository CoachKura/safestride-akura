// Pace Progression Widget for Dashboard
// Shows current progress towards 3:30/km goal

import 'package:flutter/material.dart';
import '../services/adaptive_pace_progression.dart';
import '../services/progression_plan_service.dart';
import '../screens/pace_progression_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaceProgressionWidget extends StatefulWidget {
  final String athleteId;

  const PaceProgressionWidget({
    Key? key,
    required this.athleteId,
  }) : super(key: key);

  @override
  _PaceProgressionWidgetState createState() => _PaceProgressionWidgetState();
}

class _PaceProgressionWidgetState extends State<PaceProgressionWidget> {
  Map<String, dynamic>? _progressStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressStats();
  }

  Future<void> _loadProgressStats() async {
    try {
      final stats =
          await ProgressionPlanService.getProgressStats(widget.athleteId);
      setState(() {
        _progressStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_progressStats == null || _progressStats!['has_plan'] == false) {
      return _buildNoPlanWidget();
    }

    return _buildProgressWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[800]!, Colors.grey[900]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildNoPlanWidget() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple[700]!, Colors.deepPurple[900]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your Journey to 3:30/km',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Every athlete can reach 3:30/km at Zone TH/P - regardless of where you start!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Calculate and navigate to progression plan
                await _createProgressionPlan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Calculate Your Timeline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressWidget() {
    final currentWeek = _progressStats!['current_week'] as int;
    final totalWeeks = _progressStats!['total_weeks'] as int;
    final progressPercent = _progressStats!['progress_percent'] as int;
    final currentTargetPace = _progressStats!['current_target_pace'] as double;
    final paceProgress = _progressStats!['pace_progress'] as int;
    final currentPhase = _progressStats!['current_phase'] as String;
    final weeksRemaining = _progressStats!['weeks_remaining'] as int;

    return GestureDetector(
      onTap: _viewFullPlan,
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple[700]!, Colors.deepPurple[900]!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background progress indicator
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LinearProgressIndicator(
                  value: progressPercent / 100,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.amber.withOpacity(0.2),
                  ),
                  minHeight: double.infinity,
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.emoji_events,
                            color: Colors.amber, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Journey to 3:30/km',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Week $currentWeek of $totalWeeks',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$progressPercent%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Current progress
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer,
                          label: 'Current Target',
                          value: _formatPace(currentTargetPace),
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.trending_down,
                          label: 'Pace Progress',
                          value: '$paceProgress%',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Phase and time remaining
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.flag,
                          label: 'Current Phase',
                          value: currentPhase,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_month,
                          label: 'Weeks Left',
                          value: '$weeksRemaining',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // View details button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _viewFullPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Full Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _createProgressionPlan() async {
    try {
      // Get user's current running data
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('strava_average_pace, weekly_mileage, aisri_score')
          .eq('id', widget.athleteId)
          .maybeSingle();

      // Calculate current pace (default 6:00/km if no Strava data)
      double currentPace = 6.0;
      double currentMileage = 20.0;
      int aisriScore = 50;

      if (profile != null) {
        if (profile['strava_average_pace'] != null) {
          currentPace = (profile['strava_average_pace'] / 60.0);
        }
        if (profile['weekly_mileage'] != null) {
          currentMileage = profile['weekly_mileage'].toDouble();
        }
        if (profile['aisri_score'] != null) {
          aisriScore = profile['aisri_score'];
        }
      }

      // Determine experience level
      ExperienceLevel experienceLevel;
      if (aisriScore >= 75 && currentMileage >= 60) {
        experienceLevel = ExperienceLevel.advanced;
      } else if (aisriScore >= 60 || currentMileage >= 40) {
        experienceLevel = ExperienceLevel.intermediate;
      } else {
        experienceLevel = ExperienceLevel.beginner;
      }

      // Navigate to progression screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaceProgressionScreen(
            currentPace: currentPace,
            currentMileage: currentMileage,
            aisriScore: aisriScore,
            experienceLevel: experienceLevel,
          ),
        ),
      );
    } catch (e) {
      print('Error creating progression plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating plan. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _viewFullPlan() async {
    try {
      final plan = await ProgressionPlanService.getActivePlan(widget.athleteId);
      if (plan == null) {
        throw Exception('No active plan found');
      }

      // Get experience level from progress stats
      ExperienceLevel experienceLevel = ExperienceLevel.intermediate;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaceProgressionScreen(
            currentPace: plan.startPace,
            currentMileage: plan.startMileage,
            aisriScore: plan.startAISRI,
            experienceLevel: experienceLevel,
          ),
        ),
      );
    } catch (e) {
      print('Error viewing full plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading plan. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPace(double pace) {
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}/km';
  }
}
