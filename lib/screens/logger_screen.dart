import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController(text: '5.0');
  final _durationController = TextEditingController(text: '30');
  String _activityType = 'Easy Run';
  int _rpe = 6;
  double _painLevel = 5.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String _getRPEEmoji(int rpe) {
    if (rpe <= 2) return '😌'; // Very easy
    if (rpe <= 4) return '🙂'; // Easy
    if (rpe <= 6) return '😊'; // Medium
    if (rpe <= 8) return '😅'; // Hard
    return '😰'; // Very hard
  }

  String _getRPELabel(int rpe) {
    if (rpe <= 2) return 'VERY EASY';
    if (rpe <= 4) return 'EASY';
    if (rpe <= 6) return 'MEDIUM';
    if (rpe <= 8) return 'HARD';
    return 'VERY HARD';
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final distance = double.tryParse(_distanceController.text);
      final duration = int.tryParse(_durationController.text);

      if (distance == null || duration == null) {
        throw Exception('Invalid distance or duration');
      }

      await Supabase.instance.client.from('workouts').insert({
        'user_id': userId,
        'activity_type': _activityType,
        'distance': distance,
        'duration': duration,
        'rpe': _rpe,
        'pain_level': _painLevel.toInt(),
        'notes': _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved successfully! 🏃'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _notesController.clear();
        _distanceController.text = '5.0';
        _durationController.text = '30';
        setState(() {
          _rpe = 6;
          _painLevel = 5.0;
          _activityType = 'Easy Run';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Log Workout 🏋️'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity Type
              Text(
                'Activity Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _activityType,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                  icon: const Icon(Icons.check, color: Colors.green),
                  items: [
                    'Easy Run',
                    'Long Run',
                    'Tempo Run',
                    'Interval Training',
                    'Recovery Run',
                    'Other'
                  ]
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _activityType = value!),
                ),
              ),
              const SizedBox(height: 24),

              // Distance
              Text(
                'Distance (km)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    suffixText: 'km',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter distance';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Duration
              Text(
                'Duration (minutes)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    suffixText: 'min',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // RPE Section
              Text(
                'RPE (Rate of Perceived Exertion)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // RPE Emoji Display
              Center(
                child: Column(
                  children: [
                    Text(
                      _getRPEEmoji(_rpe),
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRPELabel(_rpe),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // RPE Buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [1, 2, 6, 7, 3, 10].map((rpe) {
                  return InkWell(
                    onTap: () => setState(() => _rpe = rpe),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            _rpe == rpe ? Colors.deepPurple : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            rpe.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _rpe == rpe ? Colors.white : Colors.black,
                            ),
                          ),
                          if (_rpe == rpe)
                            Text(
                              'RPE/FF',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Pain Level
              Text(
                'Pain level',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _painLevel.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Slider(
                      value: _painLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      activeColor: Colors.deepPurple,
                      inactiveColor: Colors.grey[300],
                      onChanged: (value) => setState(() => _painLevel = value),
                    ),
                  ),
                  Text(
                    '10',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0-', style: TextStyle(color: Colors.grey[600])),
                  Text('5', style: TextStyle(color: Colors.grey[600])),
                  Text('10', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'How did the workout feel?',
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Workout',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),        ),      ),
    );
  }
}
