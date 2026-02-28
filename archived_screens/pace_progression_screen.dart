// Pace Progression Screen
// Shows personalized timeline to 3:30/km goal

import 'package:flutter/material.dart';
import '../services/adaptive_pace_progression.dart';

class PaceProgressionScreen extends StatefulWidget {
  final double currentPace;
  final double currentMileage;
  final int aisriScore;
  final ExperienceLevel experienceLevel;

  const PaceProgressionScreen({
    Key? key,
    required this.currentPace,
    required this.currentMileage,
    required this.aisriScore,
    required this.experienceLevel,
  }) : super(key: key);

  @override
  _PaceProgressionScreenState createState() => _PaceProgressionScreenState();
}

class _PaceProgressionScreenState extends State<PaceProgressionScreen> {
  late ProgressionPlan plan;
  int currentWeekIndex = 0;

  @override
  void initState() {
    super.initState();
    _calculatePlan();
  }

  void _calculatePlan() {
    plan = AdaptivePaceProgressionCalculator.calculateTimeline(
      currentPace: widget.currentPace,
      currentMileage: widget.currentMileage,
      aisriScore: widget.aisriScore,
      experienceLevel: widget.experienceLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Your Journey to 3:30/km'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section with goal
            _buildHeroSection(),

            // Timeline summary
            _buildTimelineSummary(),

            // Current week focus
            _buildCurrentWeek(),

            // Phase breakdown
            _buildPhaseBreakdown(),

            // Weekly calendar
            _buildWeeklyCalendar(),

            // Action button
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple[700]!,
            Colors.deepPurple[900]!,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 64),
          SizedBox(height: 16),
          Text(
            '3:30/km at Zone TH/P',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Universal Goal for All Athletes',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 24),

          // Progress indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: 0.0, // Starting point
                  strokeWidth: 12,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              Column(
                children: [
                  Text(
                    _formatPace(widget.currentPace),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_downward, color: Colors.amber, size: 32),
                  Text(
                    '3:30/km',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSummary() {
    final months = (plan.totalWeeks / 4.33).ceil();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.deepPurple[300], size: 28),
              SizedBox(width: 12),
              Text(
                'Your Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Duration
          _buildStatRow(
            icon: Icons.calendar_today,
            label: 'Total Duration',
            value: '${plan.totalWeeks} weeks ($months months)',
            color: Colors.blue,
          ),

          SizedBox(height: 12),

          // Pace improvement
          _buildStatRow(
            icon: Icons.speed,
            label: 'Pace Improvement',
            value: '${_formatPace(plan.startPace)} → 3:30/km',
            color: Colors.green,
          ),

          SizedBox(height: 12),

          // Mileage build
          _buildStatRow(
            icon: Icons.route,
            label: 'Mileage Build',
            value:
                '${plan.startMileage.toStringAsFixed(0)} → ${plan.goalMileage.toStringAsFixed(0)} km/week',
            color: Colors.orange,
          ),

          SizedBox(height: 12),

          // AISRI target
          _buildStatRow(
            icon: Icons.security,
            label: 'AISRI Journey',
            value: '${plan.startAISRI} → ${plan.goalAISRI}+',
            color: Colors.red,
          ),

          SizedBox(height: 20),

          // Summary text
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple[900]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              plan.summary,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWeek() {
    final currentPlan = plan.weeklyPlans[currentWeekIndex];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[700]!,
            Colors.orange[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
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
              Icon(Icons.star, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Week ${currentPlan.weekNumber}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentPlan.phase.toString().split('.').last,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Target pace
          Row(
            children: [
              Icon(Icons.timer, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Target Pace: ${_formatPace(currentPlan.targetPace)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Weekly mileage
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Weekly Mileage: ${currentPlan.weeklyMileage.toStringAsFixed(0)} km',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // AISRI target
          Row(
            children: [
              Icon(Icons.shield, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'AISRI Target: ${currentPlan.targetAISRI}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Focus areas
          Text(
            'Focus This Week:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          ...currentPlan.focus.map((focus) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        focus,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPhaseBreakdown() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training Phases',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...plan.phases.asMap().entries.map((entry) {
            final index = entry.key;
            final phase = entry.value;
            final weeksPerPhase = (plan.totalWeeks / plan.phases.length).ceil();
            final startWeek = (index * weeksPerPhase) + 1;
            final endWeek = min((index + 1) * weeksPerPhase, plan.totalWeeks);

            return _buildPhaseCard(phase, startWeek, endWeek);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(TrainingPhase phase, int startWeek, int endWeek) {
    final phaseColors = {
      TrainingPhase.foundation: Colors.blue,
      TrainingPhase.baseBuilding: Colors.green,
      TrainingPhase.speedDevelopment: Colors.orange,
      TrainingPhase.thresholdWork: Colors.purple,
      TrainingPhase.powerWork: Colors.red,
      TrainingPhase.goalAchievement: Colors.amber,
    };

    final phaseDescriptions = {
      TrainingPhase.foundation:
          'Build aerobic base, improve AISRI, form development',
      TrainingPhase.baseBuilding: 'Increase mileage safely (max 10% per week)',
      TrainingPhase.speedDevelopment: 'Add tempo runs, improve pace',
      TrainingPhase.thresholdWork:
          'Lactate threshold training, push boundaries',
      TrainingPhase.powerWork: 'High intensity 3:30/km intervals',
      TrainingPhase.goalAchievement: 'Sustain 3:30/km, race preparation',
    };

    final color = phaseColors[phase] ?? Colors.grey;
    final description = phaseDescriptions[phase] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  phase.toString().split('.').last,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Weeks $startWeek-$endWeek',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final currentPlan = plan.weeklyPlans[currentWeekIndex];

    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Workouts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...currentPlan.workouts
              .map((workout) => _buildWorkoutCard(workout))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(DailyWorkout workout) {
    final typeColors = {
      'Run': Colors.blue,
      'Strength': Colors.orange,
      'ROM': Colors.green,
      'Mobility': Colors.purple,
      'Balance': Colors.teal,
      'Rest': Colors.grey,
    };

    final color = typeColors[workout.type] ?? Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color, width: 1),
                ),
                child: Text(
                  'Day ${workout.dayNumber}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  workout.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            workout.description,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (workout.distance != null || workout.duration != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                if (workout.distance != null) ...[
                  Icon(Icons.route, color: Colors.white60, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${workout.distance!.toStringAsFixed(1)} km',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  SizedBox(width: 16),
                ],
                if (workout.duration != null) ...[
                  Icon(Icons.timer, color: Colors.white60, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${workout.duration} min',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ],
            ),
          ],
          if (workout.targetPace != null || workout.targetHR != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                if (workout.targetPace != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Pace: ${workout.targetPace}',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                if (workout.targetHR != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      workout.targetHR!,
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (workout.intervals != null && workout.intervals!.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Intervals:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            ...workout.intervals!.map((interval) => Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: color, size: 8),
                      SizedBox(width: 8),
                      Text(
                        '${interval.duration} min - ${interval.description}',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      if (interval.pace != null) ...[
                        SizedBox(width: 8),
                        Text(
                          '@ ${interval.pace}',
                          style: TextStyle(color: Colors.amber, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          // Save plan and navigate to dashboard
          _savePlanAndStart();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple[600],
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, size: 24),
            SizedBox(width: 12),
            Text(
              'Start Your Journey to 3:30/km',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePlanAndStart() {
    // TODO: Save plan to database
    // TODO: Navigate to dashboard with plan active
    Navigator.pop(context);
  }

  String _formatPace(double pace) {
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  int min(int a, int b) => a < b ? a : b;
}
