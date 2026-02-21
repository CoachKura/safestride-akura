// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Athlete Goals and Training Preferences Form
/// Used by Kura Coach to generate personalized training plans
class AthleteGoalsScreen extends StatefulWidget {
  const AthleteGoalsScreen({super.key});

  @override
  State<AthleteGoalsScreen> createState() => _AthleteGoalsScreenState();
}

class _AthleteGoalsScreenState extends State<AthleteGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  bool _loading = false;
  bool _hasExistingGoals = false;

  // Form fields
  String _primaryGoal = '10k';
  String? _targetEvent;
  DateTime? _targetDate;
  String _currentExperience = 'intermediate';
  int _daysPerWeek = 4;
  String _preferredTime = 'morning';
  int _maxSessionMinutes = 60; // Changed to int to fix slider issue

  // Personal Records
  final _current5kController = TextEditingController();
  final _current10kController = TextEditingController();
  final _currentHalfController = TextEditingController();
  final _currentFullController = TextEditingController();

  // Target Records
  final _target5kController = TextEditingController();
  final _target10kController = TextEditingController();
  final _targetHalfController = TextEditingController();
  final _targetFullController = TextEditingController();

  // Additional info
  final _injuryHistoryController = TextEditingController();
  final _obstaclesController = TextEditingController();
  final _notesController = TextEditingController();
  int _motivationLevel = 8; // Changed to int

  @override
  void initState() {
    super.initState();
    _loadExistingGoals();
  }

  @override
  void dispose() {
    _current5kController.dispose();
    _current10kController.dispose();
    _currentHalfController.dispose();
    _currentFullController.dispose();
    _target5kController.dispose();
    _target10kController.dispose();
    _targetHalfController.dispose();
    _targetFullController.dispose();
    _injuryHistoryController.dispose();
    _obstaclesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingGoals() async {
    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('athlete_goals')
          .select()
          .eq('user_id', userId)
          .eq('active', true)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _hasExistingGoals = true;
          _primaryGoal = data['primary_goal'] ?? '10k';
          _targetEvent = data['target_event'];
          _targetDate = data['target_date'] != null
              ? DateTime.parse(data['target_date'])
              : null;
          _currentExperience = data['current_experience'] ?? 'intermediate';
          _daysPerWeek = data['days_per_week'] ?? 4;
          _preferredTime = data['preferred_time'] ?? 'morning';
          _maxSessionMinutes = data['max_session_minutes'] ?? 60;

          _current5kController.text = data['current_5k_time'] ?? '';
          _current10kController.text = data['current_10k_time'] ?? '';
          _currentHalfController.text =
              data['current_half_marathon_time'] ?? '';
          _currentFullController.text = data['current_marathon_time'] ?? '';

          _target5kController.text = data['target_5k_time'] ?? '';
          _target10kController.text = data['target_10k_time'] ?? '';
          _targetHalfController.text = data['target_half_marathon_time'] ?? '';
          _targetFullController.text = data['target_marathon_time'] ?? '';

          _injuryHistoryController.text = data['injury_history'] ?? '';
          _obstaclesController.text = data['training_obstacles'] ?? '';
          _notesController.text = data['notes'] ?? '';
          _motivationLevel = data['motivation_level'] ?? 8;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goals: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      final goalsData = {
        'user_id': userId,
        'primary_goal': _primaryGoal,
        'target_event': _targetEvent,
        'target_date': _targetDate?.toIso8601String(),
        'current_experience': _currentExperience,
        'days_per_week': _daysPerWeek,
        'preferred_time': _preferredTime,
        'max_session_minutes': _maxSessionMinutes,
        'current_5k_time': _current5kController.text.isEmpty
            ? null
            : _current5kController.text,
        'current_10k_time': _current10kController.text.isEmpty
            ? null
            : _current10kController.text,
        'current_half_marathon_time': _currentHalfController.text.isEmpty
            ? null
            : _currentHalfController.text,
        'current_marathon_time': _currentFullController.text.isEmpty
            ? null
            : _currentFullController.text,
        'target_5k_time':
            _target5kController.text.isEmpty ? null : _target5kController.text,
        'target_10k_time': _target10kController.text.isEmpty
            ? null
            : _target10kController.text,
        'target_half_marathon_time': _targetHalfController.text.isEmpty
            ? null
            : _targetHalfController.text,
        'target_marathon_time': _targetFullController.text.isEmpty
            ? null
            : _targetFullController.text,
        'injury_history': _injuryHistoryController.text.isEmpty
            ? null
            : _injuryHistoryController.text,
        'training_obstacles': _obstaclesController.text.isEmpty
            ? null
            : _obstaclesController.text,
        'motivation_level': _motivationLevel,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'active': true,
      };

      if (_hasExistingGoals) {
        // Update existing goals
        await _supabase
            .from('athlete_goals')
            .update(goalsData)
            .eq('user_id', userId)
            .eq('active', true);
      } else {
        // Insert new goals
        await _supabase.from('athlete_goals').insert(goalsData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Goals saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving goals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Goals & Preferences'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Kura Coach Info Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9FF), Color(0xFF0099CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Icon and Title
                        const Icon(Icons.auto_awesome,
                            size: 48, color: Colors.white),
                        const SizedBox(height: 12),
                        const Text(
                          'Kura Coach AI',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Personal AISRI-Based Training System',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Features Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    '4-Week Training Plans',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.track_changes,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Personalized to Your Goals',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.trending_up,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Adapts Every 4 Weeks',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.watch,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Create Manually in Garmin Connect',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section Header: Set Your Goals
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.flag,
                                color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set Your Goals',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tell us what you want to achieve',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 1: Primary Goal
                  _buildSectionTitle('Primary Goal'),
                  _buildPrimaryGoalSelector(),

                  const SizedBox(height: 16),

                  // Target Event
                  TextFormField(
                    initialValue: _targetEvent,
                    decoration: const InputDecoration(
                      labelText: 'Target Event (Optional)',
                      hintText: 'e.g., Boston Marathon 2026',
                      prefixIcon: Icon(Icons.event),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        _targetEvent = value.isEmpty ? null : value,
                  ),

                  const SizedBox(height: 16),

                  // Target Date
                  InkWell(
                    onTap: _selectTargetDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Target Date (Optional)',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _targetDate != null
                            ? DateFormat('MMM dd, yyyy').format(_targetDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: _targetDate != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Experience Level
                  _buildSectionTitle('Experience Level'),
                  _buildExperienceSelector(),

                  const SizedBox(height: 24),

                  // Section 3: Training Schedule
                  _buildSectionTitle('Training Schedule'),
                  const SizedBox(height: 8),
                  const Text('Days per week:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildDaysPerWeekChips(),

                  const SizedBox(height: 16),

                  const Text('Preferred training time:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  _buildPreferredTimeSelector(),

                  const SizedBox(height: 16),

                  Text(
                    'Max workout duration: $_maxSessionMinutes minutes',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    value: _maxSessionMinutes.toDouble(),
                    min: 20,
                    max: 120,
                    divisions: 20,
                    label: '$_maxSessionMinutes min',
                    onChanged: (value) =>
                        setState(() => _maxSessionMinutes = value.toInt()),
                  ),

                  const SizedBox(height: 24),

                  // Section 4: Personal Records
                  _buildSectionTitle('Personal Records (Optional)'),
                  const Text(
                    'Format: MM:SS (e.g., 25:30 for 25 minutes 30 seconds)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildTimeField('Current 5K', _current5kController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _buildTimeField('Target 5K', _target5kController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                            'Current 10K', _current10kController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            _buildTimeField('Target 10K', _target10kController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                            'Current Half', _currentHalfController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTimeField(
                            'Target Half', _targetHalfController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                            'Current Full', _currentFullController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTimeField(
                            'Target Full', _targetFullController),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section 5: Additional Information
                  _buildSectionTitle('Additional Information'),
                  TextFormField(
                    controller: _injuryHistoryController,
                    decoration: const InputDecoration(
                      labelText: 'Injury History (Optional)',
                      hintText: 'Any recent or recurring injuries...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _obstaclesController,
                    decoration: const InputDecoration(
                      labelText: 'Training Obstacles (Optional)',
                      hintText: 'Time constraints, weather, etc...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Motivation Level: $_motivationLevel/10',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    value: _motivationLevel.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _motivationLevel.toString(),
                    onChanged: (value) =>
                        setState(() => _motivationLevel = value.toInt()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (Optional)',
                      hintText: 'Any other information...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _loading ? null : _saveGoals,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _hasExistingGoals ? 'Update Goals' : 'Save Goals',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildPrimaryGoalSelector() {
    final goals = [
      {
        'value': 'fitness',
        'label': '🏃 General Fitness',
        'icon': Icons.fitness_center
      },
      {
        'value': 'weight_loss',
        'label': '⚖️ Weight Loss',
        'icon': Icons.trending_down
      },
      {'value': '5k', 'label': '🏅 5K Race', 'icon': Icons.emoji_events},
      {'value': '10k', 'label': '🏅 10K Race', 'icon': Icons.emoji_events},
      {
        'value': 'half_marathon',
        'label': '🏅 Half Marathon',
        'icon': Icons.emoji_events
      },
      {'value': 'marathon', 'label': '🏆 Marathon', 'icon': Icons.emoji_events},
      {'value': 'speed', 'label': '⚡ Speed Improvement', 'icon': Icons.speed},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((goal) {
        final isSelected = _primaryGoal == goal['value'];
        return FilterChip(
          selected: isSelected,
          label: Text(goal['label'] as String),
          onSelected: (selected) {
            setState(() => _primaryGoal = goal['value'] as String);
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
            value: 'beginner',
            label: Text('Beginner'),
            icon: Icon(Icons.looks_one)),
        ButtonSegment(
            value: 'intermediate',
            label: Text('Intermediate'),
            icon: Icon(Icons.looks_two)),
        ButtonSegment(
            value: 'advanced',
            label: Text('Advanced'),
            icon: Icon(Icons.looks_3)),
      ],
      selected: {_currentExperience},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() => _currentExperience = newSelection.first);
      },
    );
  }

  Widget _buildDaysPerWeekChips() {
    return Wrap(
      spacing: 8,
      children: [3, 4, 5, 6, 7].map((days) {
        return ChoiceChip(
          label: Text('$days days'),
          selected: _daysPerWeek == days,
          onSelected: (selected) {
            setState(() => _daysPerWeek = days);
          },
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _buildPreferredTimeSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Morning (6 AM - 12 PM)'),
          value: 'morning',
          groupValue: _preferredTime,
          onChanged: (value) => setState(() => _preferredTime = value!),
        ),
        RadioListTile<String>(
          title: const Text('Afternoon (12 PM - 6 PM)'),
          value: 'afternoon',
          groupValue: _preferredTime,
          onChanged: (value) => setState(() => _preferredTime = value!),
        ),
        RadioListTile<String>(
          title: const Text('Evening (6 PM - 10 PM)'),
          value: 'evening',
          groupValue: _preferredTime,
          onChanged: (value) => setState(() => _preferredTime = value!),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'MM:SS',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.text,
    );
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
    );
    if (picked != null && picked != _targetDate) {
      setState(() => _targetDate = picked);
    }
  }
}
