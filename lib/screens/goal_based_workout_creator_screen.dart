import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_workout_generator_service.dart';
import 'package:intl/intl.dart';

class GoalBasedWorkoutCreatorScreen extends StatefulWidget {
  const GoalBasedWorkoutCreatorScreen({super.key});

  @override
  State<GoalBasedWorkoutCreatorScreen> createState() =>
      _GoalBasedWorkoutCreatorScreenState();
}

class _GoalBasedWorkoutCreatorScreenState
    extends State<GoalBasedWorkoutCreatorScreen> {
  String _selectedGoal = 'fitness';
  int _weeksToGoal = 12;
  int _currentWeeklyKm = 15;
  int _trainingDaysPerWeek = 4;
  String _fitnessLevel = 'intermediate';
  DateTime? _targetRaceDate;
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedPlan;
  double _aisriScore = 70.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get AISRI score
      final aisriData = await Supabase.instance.client
          .from('aisri_assessments')
          .select('aisri_score, total_score')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Get recent weekly distance
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentWorkouts = await Supabase.instance.client
          .from('workouts')
          .select('distance_km, distance')
          .eq('user_id', userId)
          .gte('created_at', sevenDaysAgo.toIso8601String());

      final weeklyKm = recentWorkouts.fold(0.0, (sum, w) {
        final distance = (w['distance_km'] ?? w['distance'] ?? 0.0) as num;
        return sum + distance.toDouble();
      });

      setState(() {
        _aisriScore = ((aisriData?['total_score'] ?? aisriData?['aisri_score']) ?? 70.0).toDouble();
        _currentWeeklyKm = weeklyKm.round().clamp(5, 100);
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _generatePlan() async {
    setState(() => _isGenerating = true);

    try {
      final plan = await AIWorkoutGeneratorService.generateWorkoutPlan(
        goalType: _selectedGoal,
        weeksToGoal: _weeksToGoal,
        currentWeeklyKm: _currentWeeklyKm,
        trainingDaysPerWeek: _trainingDaysPerWeek,
        fitnessLevel: _fitnessLevel,
        aisriScore: _aisriScore,
        targetRaceDate: _targetRaceDate?.toIso8601String(),
      );

      setState(() {
        _generatedPlan = plan;
        _isGenerating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${plan['total_workouts']} workouts!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToCalendar() async {
    if (_generatedPlan == null) return;

    setState(() => _isGenerating = true);

    try {
      final workouts = (_generatedPlan!['workouts'] as List)
          .cast<Map<String, dynamic>>();
      
      await AIWorkoutGeneratorService.saveWorkoutsToCalendar(workouts);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Workouts saved to calendar!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workouts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('AI Workout Generator'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_generatedPlan != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveToCalendar,
              tooltip: 'Save to Calendar',
            ),
        ],
      ),
      body: _generatedPlan == null ? _buildInputForm() : _buildPlanPreview(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'AI Training Plan Generator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer a few questions and let AI create a personalized training plan for you',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Goal Selection
          _buildSectionTitle('What\'s your goal?'),
          _buildGoalSelector(),
          const SizedBox(height: 24),

          // Target Date (for races)
          if (_selectedGoal != 'fitness' && _selectedGoal != 'weight_loss') ...[
            _buildSectionTitle('Target Race Date (Optional)'),
            _buildDatePicker(),
            const SizedBox(height: 24),
          ],

          // Training Duration
          _buildSectionTitle('Training Duration'),
          _buildWeekSlider(),
          const SizedBox(height: 24),

          // Current Fitness
          _buildSectionTitle('Current Weekly Distance'),
          _buildWeeklyKmSlider(),
          const SizedBox(height: 24),

          // Training Days
          _buildSectionTitle('Training Days Per Week'),
          _buildTrainingDaysSelector(),
          const SizedBox(height: 24),

          // Fitness Level
          _buildSectionTitle('Fitness Level'),
          _buildFitnessLevelSelector(),
          const SizedBox(height: 24),

          // AISRI Info
          _buildAISRIInfo(),
          const SizedBox(height: 32),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generatePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome),
                        SizedBox(width: 8),
                        Text(
                          'Generate Training Plan',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGoalSelector() {
    final goals = [
      {'id': 'fitness', 'name': 'General Fitness', 'icon': Icons.fitness_center},
      {'id': '5k', 'name': '5K Race', 'icon': Icons.directions_run},
      {'id': '10k', 'name': '10K Race', 'icon': Icons.directions_run},
      {'id': 'half_marathon', 'name': 'Half Marathon', 'icon': Icons.emoji_events},
      {'id': 'marathon', 'name': 'Marathon', 'icon': Icons.emoji_events},
      {'id': 'weight_loss', 'name': 'Weight Loss', 'icon': Icons.monitor_weight},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: goals.map((goal) {
        final isSelected = _selectedGoal == goal['id'];
        return InkWell(
          onTap: () => setState(() => _selectedGoal = goal['id'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepPurple : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  goal['icon'] as IconData,
                  color: isSelected ? Colors.white : Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  goal['name'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _targetRaceDate ?? DateTime.now().add(const Duration(days: 90)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _targetRaceDate = date;
            _weeksToGoal = date.difference(DateTime.now()).inDays ~/ 7;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Text(
              _targetRaceDate == null
                  ? 'Select race date'
                  : DateFormat('MMM dd, yyyy').format(_targetRaceDate!),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weeks:', style: TextStyle(fontSize: 16)),
                Text(
                  '$_weeksToGoal weeks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            Slider(
              value: _weeksToGoal.toDouble(),
              min: 4,
              max: 24,
              divisions: 20,
              activeColor: Colors.deepPurple,
              onChanged: (value) => setState(() => _weeksToGoal = value.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyKmSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current km/week:', style: TextStyle(fontSize: 16)),
                Text(
                  '$_currentWeeklyKm km',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            Slider(
              value: _currentWeeklyKm.toDouble(),
              min: 5,
              max: 80,
              divisions: 15,
              activeColor: Colors.deepPurple,
              onChanged: (value) =>
                  setState(() => _currentWeeklyKm = value.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingDaysSelector() {
    return Row(
      children: [3, 4, 5, 6, 7].map((days) {
        final isSelected = _trainingDaysPerWeek == days;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _trainingDaysPerWeek = days),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isSelected ? Colors.deepPurple : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  '$days',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFitnessLevelSelector() {
    final levels = [
      {'id': 'beginner', 'name': 'Beginner', 'color': Colors.green},
      {'id': 'intermediate', 'name': 'Intermediate', 'color': Colors.orange},
      {'id': 'advanced', 'name': 'Advanced', 'color': Colors.red},
    ];

    return Row(
      children: levels.map((level) {
        final isSelected = _fitnessLevel == level['id'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _fitnessLevel = level['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (level['color'] as Color)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (level['color'] as Color)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  level['name'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAISRIInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _aisriScore >= 70
            ? Colors.green.shade50
            : _aisriScore >= 60
                ? Colors.orange.shade50
                : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _aisriScore >= 70
              ? Colors.green
              : _aisriScore >= 60
                  ? Colors.orange
                  : Colors.red,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _aisriScore >= 70
                ? Icons.check_circle
                : _aisriScore >= 60
                    ? Icons.warning
                    : Icons.error,
            color: _aisriScore >= 70
                ? Colors.green
                : _aisriScore >= 60
                    ? Colors.orange
                    : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your AISRI Score',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_aisriScore.toStringAsFixed(0)}/100 - Plan adjusted for your fitness level',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanPreview() {
    final workouts = (_generatedPlan!['workouts'] as List).cast<Map<String, dynamic>>();
    final weeklyProgression = (_generatedPlan!['weekly_progression'] as List).cast<double>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Plan Generated!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_generatedPlan!['total_workouts']} workouts over ${_generatedPlan!['total_weeks']} weeks',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Weekly Progression Chart
          const Text(
            'Weekly Distance Progression',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weeklyProgression.length,
              itemBuilder: (context, index) {
                final km = weeklyProgression[index];
                final maxKm = weeklyProgression.reduce((a, b) => a > b ? a : b);
                final height = (km / maxKm) * 100;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        km.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'W${index + 1}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Workouts Preview (First 5)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Workouts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _showAllWorkouts,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...workouts.take(5).map((workout) => _buildWorkoutPreviewCard(workout)),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _saveToCalendar,
              icon: const Icon(Icons.calendar_today),
              label: const Text(
                'Save to Calendar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _generatedPlan = null),
              icon: const Icon(Icons.refresh),
              label: const Text('Generate New Plan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPreviewCard(Map<String, dynamic> workout) {
    final date = DateTime.parse(workout['scheduled_date']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIntensityColor(workout['intensity']),
          child: const Icon(Icons.directions_run, color: Colors.white, size: 20),
        ),
        title: Text(
          workout['type'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd').format(date)} • ${workout['distance_km'].toStringAsFixed(1)}km • ${workout['duration_minutes']}min',
        ),
        trailing: Icon(
          _getIntensityIcon(workout['intensity']),
          color: _getIntensityColor(workout['intensity']),
        ),
      ),
    );
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getIntensityIcon(String intensity) {
    switch (intensity) {
      case 'low':
        return Icons.battery_2_bar;
      case 'moderate':
        return Icons.battery_5_bar;
      case 'high':
        return Icons.battery_full;
      default:
        return Icons.battery_3_bar;
    }
  }

  void _showAllWorkouts() {
    final workouts = (_generatedPlan!['workouts'] as List).cast<Map<String, dynamic>>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Workouts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: workouts.length,
                  itemBuilder: (context, index) => _buildWorkoutPreviewCard(workouts[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
