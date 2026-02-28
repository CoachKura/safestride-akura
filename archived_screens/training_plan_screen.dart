// Training Plan Generator Screen
// Generates personalized 4-week training plans based on Strava data

import 'package:flutter/material.dart';
import '../services/training_plan_service.dart';
import 'garmin_workout_builder_screen.dart';

class TrainingPlanScreen extends StatefulWidget {
  const TrainingPlanScreen({super.key});

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  final TrainingPlanService _planService = TrainingPlanService();

  AthleteProfile? _profile;
  TrainingPlan? _generatedPlan;
  TrainingGoal _selectedGoal = TrainingGoal.general5k;
  bool _isAnalyzing = false;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeProfile();
  }

  Future<void> _analyzeProfile() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final profile = await _planService.analyzeAthleteProfile();
      setState(() {
        _profile = profile;
        _isAnalyzing = false;
        // Auto-select goal based on fitness level
        _selectedGoal = _suggestGoal(profile.level);
      });
    } catch (e) {
      setState(() {
        _error = 'Error analyzing profile: $e';
        _isAnalyzing = false;
      });
    }
  }

  TrainingGoal _suggestGoal(FitnessLevel level) {
    switch (level) {
      case FitnessLevel.beginner:
        return TrainingGoal.general5k;
      case FitnessLevel.intermediate:
        return TrainingGoal.general10k;
      case FitnessLevel.advanced:
        return TrainingGoal.halfMarathon;
      case FitnessLevel.elite:
        return TrainingGoal.marathon;
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final plan = await _planService.generateTrainingPlan(goal: _selectedGoal);
      setState(() {
        _generatedPlan = plan;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error generating plan: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _savePlan() async {
    if (_generatedPlan == null) return;

    setState(() => _isSaving = true);

    try {
      await _planService.savePlan(_generatedPlan!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Training plan saved to calendar!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('AI Training Plan'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildAnalyzingView()
            : _generatedPlan != null
                ? _buildPlanView()
                : _buildSetupView(),
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Analyzing your Strava data...',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Looking at your recent activities',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Summary Card
          if (_profile != null) _buildProfileCard(),

          const SizedBox(height: 24),

          // Goal Selection
          const Text(
            'SELECT YOUR TRAINING GOAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          _buildGoalSelector(),

          const SizedBox(height: 24),

          // What you'll get
          _buildWhatYouGetCard(),

          const SizedBox(height: 24),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generatePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Generate My 4-Week Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final profile = _profile!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.analytics, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Fitness Profile',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      profile.levelDescription,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('Weekly Distance',
                  '${profile.weeklyDistance.toStringAsFixed(1)} km'),
              _buildStatItem(
                  'Avg Pace', '${profile.avgPace.toStringAsFixed(1)} min/km'),
              _buildStatItem(
                  'Runs/Week', profile.weeklyRuns.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                  'Longest Run', '${profile.longestRun.toStringAsFixed(1)} km'),
              if (profile.avgHeartRate > 0)
                _buildStatItem('Avg HR', '${profile.avgHeartRate.toInt()} bpm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: TrainingGoal.values.map((goal) {
          final isSelected = _selectedGoal == goal;
          return InkWell(
            onTap: () => setState(() => _selectedGoal = goal),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.withValues(alpha: 0.2) : null,
                border: isSelected
                    ? Border.all(color: Colors.green, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getGoalIcon(goal),
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGoalTitle(goal),
                          style: TextStyle(
                            color: isSelected ? Colors.green : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getGoalDescription(goal),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getGoalIcon(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.general5k:
        return Icons.directions_run;
      case TrainingGoal.general10k:
        return Icons.timer;
      case TrainingGoal.halfMarathon:
        return Icons.emoji_events;
      case TrainingGoal.marathon:
        return Icons.military_tech;
      case TrainingGoal.speedImprovement:
        return Icons.speed;
      case TrainingGoal.enduranceBase:
        return Icons.fitness_center;
      case TrainingGoal.maintenance:
        return Icons.loop;
    }
  }

  String _getGoalTitle(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.general5k:
        return '5K Training';
      case TrainingGoal.general10k:
        return '10K Training';
      case TrainingGoal.halfMarathon:
        return 'Half Marathon';
      case TrainingGoal.marathon:
        return 'Marathon';
      case TrainingGoal.speedImprovement:
        return 'Speed Improvement';
      case TrainingGoal.enduranceBase:
        return 'Endurance Base';
      case TrainingGoal.maintenance:
        return 'Fitness Maintenance';
    }
  }

  String _getGoalDescription(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.general5k:
        return 'Build fitness for 5K races';
      case TrainingGoal.general10k:
        return 'Progress to 10K distance';
      case TrainingGoal.halfMarathon:
        return 'Train for 21.1km race';
      case TrainingGoal.marathon:
        return 'Prepare for 42.2km marathon';
      case TrainingGoal.speedImprovement:
        return 'Get faster at any distance';
      case TrainingGoal.enduranceBase:
        return 'Build aerobic foundation';
      case TrainingGoal.maintenance:
        return 'Maintain current fitness';
    }
  }

  Widget _buildWhatYouGetCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PLAN INCLUDES',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureRow(
              Icons.calendar_month, '4 weeks of structured training'),
          _buildFeatureRow(Icons.auto_graph, 'Progressive overload built in'),
          _buildFeatureRow(Icons.speed, 'Pace targets based on your fitness'),
          _buildFeatureRow(Icons.favorite, 'Recovery weeks included'),
          _buildFeatureRow(Icons.edit_note, 'Customizable workouts'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanView() {
    final plan = _generatedPlan!;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.totalWorkouts} workouts • ${plan.totalDistance.toStringAsFixed(0)} km total',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : _savePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save to Calendar'),
              ),
            ],
          ),
        ),

        // Weeks
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plan.weeks.length,
            itemBuilder: (context, index) => _buildWeekCard(plan.weeks[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCard(TrainingWeek week) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'WEEK ${week.weekNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    week.theme,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${week.totalDistance.toStringAsFixed(0)} km',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),

          // Days
          ...week.days.map((day) => _buildDayRow(day)),
        ],
      ),
    );
  }

  Widget _buildDayRow(TrainingDay day) {
    final isRestDay = day.isRestDay;

    return InkWell(
      onTap: day.workout != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GarminWorkoutBuilderScreen(
                    existingWorkout: day.workout,
                    scheduledDate: day.date,
                  ),
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                day.dayOfWeek.substring(0, 3),
                style: TextStyle(
                  color: isRestDay ? Colors.grey[600] : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                isRestDay ? 'Rest Day' : (day.workout?.name ?? 'Workout'),
                style: TextStyle(
                  color: isRestDay ? Colors.grey[600] : Colors.white,
                  fontWeight: isRestDay ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
            if (!isRestDay && day.workout != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }
}
