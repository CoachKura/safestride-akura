import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class WorkoutCreatorScreen extends StatefulWidget {
  const WorkoutCreatorScreen({super.key});

  @override
  State<WorkoutCreatorScreen> createState() => _WorkoutCreatorScreenState();
}

class _WorkoutCreatorScreenState extends State<WorkoutCreatorScreen> {
  String _selectedCategory = 'Running';
  String _selectedType = 'Easy Run';
  final _workoutNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  int _sets = 3;
  int _reps = 10;
  int _restSeconds = 60;
  bool _isLoading = false;

  final Map<String, List<Map<String, dynamic>>> _workoutTemplates = {
    'Running': [
      {
        'name': 'Easy Run',
        'description': 'Conversational pace for aerobic base building',
        'icon': Icons.directions_walk,
        'color': Colors.green,
        'standards': {
          'duration': '30-60 min',
          'intensity': 'Zone F (Foundation): 60-70% max HR',
          'pace': 'Conversational',
          'frequency': '3-5x per week',
        },
      },
      {
        'name': 'Tempo Run',
        'description': 'Comfortably hard pace for lactate threshold',
        'icon': Icons.speed,
        'color': Colors.orange,
        'standards': {
          'duration': '20-40 min',
          'intensity': 'Zone TH (Threshold ⭐): 80-87% max HR',
          'pace': '10K-15K race pace',
          'frequency': '1-2x per week',
        },
      },
      {
        'name': 'Interval Training',
        'description': 'High-intensity intervals for VO2 max',
        'icon': Icons.flash_on,
        'color': Colors.red,
        'standards': {
          'duration': '30-45 min total',
          'intensity': 'Zone P (Power): 87-95% max HR',
          'structure': '4-8 x 800m @ 5K pace',
          'rest': '2-3 min recovery',
          'frequency': '1x per week',
        },
      },
      {
        'name': 'Long Run',
        'description': 'Extended duration for endurance',
        'icon': Icons.landscape,
        'color': Colors.blue,
        'standards': {
          'duration': '60-120 min',
          'intensity': 'Zone F-EN (Foundation-Endurance): 60-80% max HR',
          'distance': '15-30 km',
          'frequency': '1x per week',
        },
      },
      {
        'name': 'Fartlek',
        'description': 'Unstructured speed play',
        'icon': Icons.shuffle,
        'color': Colors.amber,
        'standards': {
          'duration': '40-60 min',
          'intensity': 'Variable: Zone EN-P (70-95% max HR)',
          'structure': 'Mix fast/slow as you feel',
          'frequency': '1x per week',
        },
      },
      {
        'name': 'Hill Repeats',
        'description': 'Strength and power on inclines',
        'icon': Icons.terrain,
        'color': Colors.brown,
        'standards': {
          'duration': '30-45 min',
          'structure': '6-10 x 90sec uphill',
          'intensity': 'Zone TH-P (Threshold-Power): 80-95% max HR',
          'recovery': 'Jog back down',
          'frequency': '1x per week',
        },
      },
    ],
    'Strengthening': [
      {
        'name': 'Lower Body Strength',
        'description': 'Build leg strength and power',
        'icon': Icons.fitness_center,
        'color': Colors.deepPurple,
        'standards': {
          'exercises': 'Squats, Lunges, Deadlifts',
          'sets': '3-4 sets',
          'reps': '8-12 reps',
          'rest': '90-120 sec',
          'frequency': '2x per week',
        },
      },
      {
        'name': 'Core Stability',
        'description': 'Core strength for running economy',
        'icon': Icons.accessibility_new,
        'color': Colors.indigo,
        'standards': {
          'exercises': 'Planks, Bird Dogs, Dead Bugs',
          'duration': '30-45 sec holds',
          'sets': '3 rounds',
          'rest': '30 sec',
          'frequency': '3-4x per week',
        },
      },
      {
        'name': 'Plyometrics',
        'description': 'Explosive power development',
        'icon': Icons.sports_gymnastics,
        'color': Colors.pink,
        'standards': {
          'exercises': 'Box Jumps, Bounds, Hop',
          'sets': '3-4 sets',
          'reps': '6-10 reps',
          'rest': '2-3 min',
          'frequency': '1-2x per week',
        },
      },
      {
        'name': 'Upper Body',
        'description': 'Arm and shoulder strength',
        'icon': Icons.back_hand,
        'color': Colors.teal,
        'standards': {
          'exercises': 'Push-ups, Rows, Shoulder Press',
          'sets': '3 sets',
          'reps': '10-15 reps',
          'rest': '60 sec',
          'frequency': '2x per week',
        },
      },
      {
        'name': 'Single Leg Strength',
        'description': 'Balance and stability',
        'icon': Icons.sentiment_very_satisfied,
        'color': Colors.cyan,
        'standards': {
          'exercises': 'Single Leg Squats, Step-ups',
          'sets': '3 sets each leg',
          'reps': '8-12 reps',
          'rest': '60 sec',
          'frequency': '2x per week',
        },
      },
    ],
    'Rehab': [
      {
        'name': 'Ankle Mobility',
        'description': 'Dorsiflexion and stability',
        'icon': Icons.airline_seat_legroom_normal,
        'color': Colors.lightBlue,
        'standards': {
          'exercises': 'Ankle Circles, Calf Stretches',
          'duration': '10-15 min',
          'sets': '2-3 rounds',
          'frequency': 'Daily',
        },
      },
      {
        'name': 'Hip Mobility',
        'description': 'Hip flexor and glute activation',
        'icon': Icons.self_improvement,
        'color': Colors.lightGreen,
        'standards': {
          'exercises': 'Hip Circles, Glute Bridges',
          'duration': '10-15 min',
          'sets': '2-3 rounds',
          'frequency': 'Daily',
        },
      },
      {
        'name': 'Knee Rehab',
        'description': 'Strengthen around the knee',
        'icon': Icons.healing,
        'color': Colors.orange,
        'standards': {
          'exercises': 'Leg Extensions, Hamstring Curls',
          'sets': '2-3 sets',
          'reps': '15-20 reps light',
          'frequency': '3-4x per week',
        },
      },
      {
        'name': 'Plantar Fascia Care',
        'description': 'Foot arch strengthening',
        'icon': Icons.water,
        'color': Colors.purple,
        'standards': {
          'exercises': 'Towel Scrunches, Arch Lifts',
          'duration': '10 min',
          'sets': '2 rounds',
          'frequency': 'Daily',
        },
      },
      {
        'name': 'IT Band Release',
        'description': 'Foam rolling and stretches',
        'icon': Icons.roller_shades,
        'color': Colors.brown,
        'standards': {
          'exercises': 'Foam Roll, IT Band Stretch',
          'duration': '10-15 min',
          'frequency': 'After each run',
        },
      },
      {
        'name': 'Recovery Routine',
        'description': 'Full body recovery protocol',
        'icon': Icons.spa,
        'color': Colors.teal,
        'standards': {
          'exercises': 'Static Stretching, Foam Rolling',
          'duration': '20-30 min',
          'frequency': '2-3x per week',
        },
      },
    ],
  };

  @override
  void dispose() {
    _workoutNameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentTemplates =>
      _workoutTemplates[_selectedCategory] ?? [];

  Map<String, dynamic> get _selectedTemplate =>
      _currentTemplates.firstWhere(
        (t) => t['name'] == _selectedType,
        orElse: () => _currentTemplates.first,
      );

  Future<void> _saveWorkout() async {
    if (_workoutNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final workoutData = {
        'user_id': userId,
        'workout_name': _workoutNameController.text.trim(),
        'workout_type': _selectedType,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'duration_minutes': int.tryParse(_durationController.text) ?? 0,
        'distance_km': double.tryParse(_distanceController.text),
        'sets': _selectedCategory == 'Strengthening' ? _sets : null,
        'reps': _selectedCategory == 'Strengthening' ? _reps : null,
        'rest_seconds': _restSeconds,
        'standards': _selectedTemplate['standards'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('custom_workouts')
          .insert(workoutData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout created successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      developer.log('Error saving workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Workout'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selection
            Text(
              'Workout Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CategoryChip(
                    label: 'Running',
                    icon: Icons.directions_run,
                    isSelected: _selectedCategory == 'Running',
                    onTap: () => setState(() {
                      _selectedCategory = 'Running';
                      _selectedType = _currentTemplates.first['name'];
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CategoryChip(
                    label: 'Strength',
                    icon: Icons.fitness_center,
                    isSelected: _selectedCategory == 'Strengthening',
                    onTap: () => setState(() {
                      _selectedCategory = 'Strengthening';
                      _selectedType = _currentTemplates.first['name'];
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CategoryChip(
                    label: 'Rehab',
                    icon: Icons.healing,
                    isSelected: _selectedCategory == 'Rehab',
                    onTap: () => setState(() {
                      _selectedCategory = 'Rehab';
                      _selectedType = _currentTemplates.first['name'];
                    }),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Workout Type Grid
            Text(
              'Select Workout Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _currentTemplates.length,
              itemBuilder: (context, index) {
                final template = _currentTemplates[index];
                final isSelected = template['name'] == _selectedType;

                return GestureDetector(
                  onTap: () => setState(() => _selectedType = template['name']),
                  child: Card(
                    elevation: isSelected ? 8 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? template['color']
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            template['color'].withValues(alpha: 0.2),
                            template['color'].withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            template['icon'],
                            size: 36,
                            color: template['color'],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            template['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: template['color'],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Standards Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedTemplate['icon'],
                          color: _selectedTemplate['color'],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedTemplate['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedTemplate['color'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedCategory,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedTemplate['description'],
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Standards & Guidelines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_selectedTemplate['standards'] as Map<String, dynamic>)
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 13,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${entry.key}: ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: '${entry.value}'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),

            // AISRI Zones Info Card
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '6 AISRI Training Zones',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Heart rate zones calculated from: Max HR = 208 - (0.7 × Age)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Workout Details Form
            Text(
              'Workout Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _workoutNameController,
              decoration: InputDecoration(
                labelText: 'Workout Name *',
                hintText: 'e.g., Morning $_selectedType',
                prefixIcon: const Icon(Icons.title),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add notes or instructions',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (min)',
                      prefixIcon: Icon(Icons.timer),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedCategory == 'Running')
                  Expanded(
                    child: TextField(
                      controller: _distanceController,
                      decoration: const InputDecoration(
                        labelText: 'Distance (km)',
                        prefixIcon: Icon(Icons.straighten),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
              ],
            ),

            if (_selectedCategory == 'Strengthening') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sets: $_sets',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Slider(
                          value: _sets.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_sets sets',
                          onChanged: (value) =>
                              setState(() => _sets = value.round()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reps: $_reps',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Slider(
                          value: _reps.toDouble(),
                          min: 5,
                          max: 30,
                          divisions: 25,
                          label: '$_reps reps',
                          onChanged: (value) =>
                              setState(() => _reps = value.round()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rest: $_restSeconds sec',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _restSeconds.toDouble(),
                  min: 15,
                  max: 300,
                  divisions: 19,
                  label: '$_restSeconds sec',
                  onChanged: (value) =>
                      setState(() => _restSeconds = value.round()),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveWorkout,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, size: 24),
                label: Text(
                  _isLoading ? 'Saving...' : 'Create Workout',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTemplate['color'],
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
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
