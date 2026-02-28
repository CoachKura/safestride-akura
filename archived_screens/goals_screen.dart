// lib/screens/goals_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/athlete_goal.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final supabase = Supabase.instance.client;
  List<AthleteGoal> goals = [];
  bool isLoading = true;
  String filter = 'active'; // active, completed, all

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      var query = supabase
          .from('athlete_goals')
          .select()
          .eq('user_id', userId)
          .eq('active', true);

      final response = await query.order('target_date', ascending: true);

      setState(() {
        goals = (response as List)
            .map((json) => AthleteGoal.fromJson(json))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goals: $e')),
        );
      }
    }
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'complete_distance';
    double? targetValue;
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'e.g., Run first 5K',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Goal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'complete_distance', child: Text('Complete Distance')),
                    DropdownMenuItem(value: 'time_target', child: Text('Time Target')),
                    DropdownMenuItem(value: 'consistency', child: Text('Consistency')),
                    DropdownMenuItem(value: 'weight_loss', child: Text('Weight Loss')),
                    DropdownMenuItem(value: 'aisri_score', child: Text('AISRI Score')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _getTargetLabel(selectedType),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    targetValue = double.tryParse(value);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Target Date: ${DateFormat('MMM dd, yyyy').format(targetDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => targetDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || targetValue == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                await _addGoal(
                  titleController.text,
                  selectedType,
                  targetValue!,
                  targetDate,
                  descriptionController.text,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTargetLabel(String type) {
    switch (type) {
      case 'complete_distance':
        return 'Target Distance (km)';
      case 'time_target':
        return 'Target Time (minutes)';
      case 'consistency':
        return 'Workouts per Week';
      case 'weight_loss':
        return 'Target Weight (kg)';
      case 'aisri_score':
        return 'Target AISRI Score';
      default:
        return 'Target Value';
    }
  }

  Future<void> _addGoal(String title, String type, double targetValue, DateTime targetDate, String? description) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = {
        'user_id': userId,
        'goal_type': type,
        'goal_title': title,
        'goal_description': description?.isNotEmpty == true ? description : null,
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'target_date': targetDate.toIso8601String().split('T')[0],
        'status': 'active',
        'progress_percentage': 0,
      };

      // Add type-specific target
      switch (type) {
        case 'complete_distance':
          data['target_distance_km'] = targetValue;
          break;
        case 'time_target':
          data['target_time_minutes'] = targetValue.round();
          break;
        case 'consistency':
          data['target_workouts_per_week'] = targetValue.round();
          break;
        case 'weight_loss':
          data['target_weight_kg'] = targetValue;
          break;
        case 'aisri_score':
          data['target_aisri_score'] = targetValue.round();
          break;
      }

      await supabase.from('athlete_goals').insert(data);

      await _loadGoals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating goal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          PopupMenuButton<String>(
            initialValue: filter,
            onSelected: (value) {
              setState(() => filter = value);
              _loadGoals();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'active', child: Text('Active Goals')),
              const PopupMenuItem(value: 'completed', child: Text('Completed Goals')),
              const PopupMenuItem(value: 'all', child: Text('All Goals')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : goals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goals.length,
                  itemBuilder: (context, index) => _buildGoalCard(goals[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            filter == 'active' ? 'No active goals' : 'No goals yet',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddGoalDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Goal'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(AthleteGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(int.parse(goal.priorityColor.replaceFirst('#', '0xFF')))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getGoalIcon(goal.goalType),
                    color: Color(int.parse(goal.priorityColor.replaceFirst('#', '0xFF'))),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.goalTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        goal.goalTypeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(int.parse(goal.statusColor.replaceFirst('#', '0xFF')))
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    goal.statusDisplay,
                    style: TextStyle(
                      color: Color(int.parse(goal.statusColor.replaceFirst('#', '0xFF'))),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      goal.targetDisplay,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      goal.isOverdue ? 'Overdue' : 'Days Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: goal.isOverdue ? Colors.red : Colors.grey[600],
                      ),
                    ),
                    Text(
                      goal.daysUntilTarget.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: goal.isOverdue ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progressPercentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(int.parse(goal.statusColor.replaceFirst('#', '0xFF'))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal.progressPercentage}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (goal.goalDescription?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                goal.goalDescription!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getGoalIcon(String type) {
    switch (type) {
      case 'complete_distance':
        return Icons.directions_run;
      case 'time_target':
        return Icons.timer;
      case 'consistency':
        return Icons.event_repeat;
      case 'weight_loss':
        return Icons.monitor_weight;
      case 'aisri_score':
        return Icons.trending_up;
      case 'strength_gain':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.accessibility_new;
      default:
        return Icons.emoji_events;
    }
  }
}
