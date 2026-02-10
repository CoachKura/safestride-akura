import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/kura_coach_adaptive_service.dart';

/// Admin screen to generate training plans for multiple athletes
class AdminBatchGenerationScreen extends StatefulWidget {
  const AdminBatchGenerationScreen({super.key});

  @override
  State<AdminBatchGenerationScreen> createState() => _AdminBatchGenerationScreenState();
}

class _AdminBatchGenerationScreenState extends State<AdminBatchGenerationScreen> {
  final _supabase = Supabase.instance.client;
  
  bool _loading = false;
  bool _analyzing = false;
  List<Map<String, dynamic>> _athletes = [];
  List<Map<String, dynamic>> _analysisResults = [];
  List<Map<String, dynamic>> _generationResults = [];
  final Set<String> _selectedAthletes = {};
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAthletes();
  }

  Future<void> _loadAthletes() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Loading athletes...';
    });

    try {
      // Get athletes with recent AISRI assessments
      final data = await _supabase
          .from('athlete_profiles')
          .select('''
            user_id,
            full_name,
            date_of_birth,
            aisri_assessments!inner(
              id,
              created_at,
              running_performance,
              strength,
              rom,
              balance,
              mobility,
              alignment
            )
          ''')
          .limit(10);

      // Check for goals
      for (var athlete in data) {
        final goals = await _supabase
            .from('athlete_goals')
            .select()
            .eq('user_id', athlete['user_id'])
            .maybeSingle();
        
        athlete['has_goals'] = goals != null;
        athlete['goals_data'] = goals;
      }

      setState(() {
        _athletes = List<Map<String, dynamic>>.from(data);
        _loading = false;
        _statusMessage = '${_athletes.length} athletes loaded';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMessage = 'Error loading athletes: $e';
      });
    }
  }

  Future<void> _analyzeAthletes() async {
    if (_selectedAthletes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one athlete')),
      );
      return;
    }

    setState(() {
      _analyzing = true;
      _analysisResults = [];
      _statusMessage = 'Analyzing ${_selectedAthletes.length} athletes...';
    });

    try {
      List<Map<String, dynamic>> results = [];
      
      for (var userId in _selectedAthletes) {
        final state = await KuraCoachAdaptiveService.analyzeAthleteState(userId);
        results.add(state);
      }

      setState(() {
        _analysisResults = results;
        _analyzing = false;
        _statusMessage = 'Analysis complete for ${results.length} athletes';
      });
    } catch (e) {
      setState(() {
        _analyzing = false;
        _statusMessage = 'Error analyzing: $e';
      });
    }
  }

  Future<void> _generatePlans() async {
    if (_analysisResults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please analyze athletes first')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _generationResults = [];
      _statusMessage = 'Generating plans for ${_analysisResults.length} athletes...';
    });

    try {
      List<Map<String, dynamic>> results = [];
      
      for (var athleteState in _analysisResults) {
        try {
          final planId = await KuraCoachAdaptiveService.generateInitial4WeekPlan(
            userId: athleteState['user_id'],
            athleteState: athleteState,
          );

          results.add({
            'user_id': athleteState['user_id'],
            'name': athleteState['athlete_name'],
            'plan_id': planId,
            'training_phase': athleteState['training_phase'],
            'aisri_score': athleteState['aisri_score'],
            'status': 'success',
          });
        } catch (e) {
          results.add({
            'user_id': athleteState['user_id'],
            'name': athleteState['athlete_name'],
            'status': 'error',
            'error': e.toString(),
          });
        }
      }

      setState(() {
        _generationResults = results;
        _loading = false;
        _statusMessage = 'Plans generated: ${results.where((r) => r['status'] == 'success').length}/${results.length} successful';
      });

      // Show success dialog
      if (mounted) {
        _showResultsDialog();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMessage = 'Error generating plans: $e';
      });
    }
  }

  void _showResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Plan Generation Complete'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully generated ${_generationResults.where((r) => r['status'] == 'success').length} training plans',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._generationResults.map((result) {
                final isSuccess = result['status'] == 'success';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result['name'],
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (isSuccess)
                              Text(
                                '${result['training_phase']} • AISRI: ${result['aisri_score'].toStringAsFixed(1)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              )
                            else
                              Text(
                                'Error: ${result['error']}',
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Plan Generation'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusMessage.isEmpty ? 'Ready to generate plans' : _statusMessage,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (_selectedAthletes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_selectedAthletes.length} athletes selected',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedAthletes.isEmpty || _analyzing || _loading
                        ? null
                        : _analyzeAthletes,
                    icon: _analyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics),
                    label: Text(_analyzing ? 'Analyzing...' : 'Analyze Athletes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _analysisResults.isEmpty || _loading
                        ? null
                        : _generatePlans,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.rocket_launch),
                    label: Text(_loading ? 'Generating...' : 'Generate Plans'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Athletes List
          Expanded(
            child: _loading && _athletes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _athletes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No athletes found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Make sure athletes have completed AISRI evaluations',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _athletes.length,
                        itemBuilder: (context, index) {
                          final athlete = _athletes[index];
                          final userId = athlete['user_id'];
                          final isSelected = _selectedAthletes.contains(userId);
                          final hasGoals = athlete['has_goals'] ?? false;
                          
                          final assessment = athlete['aisri_assessments'] is List
                              ? athlete['aisri_assessments'][0]
                              : athlete['aisri_assessments'];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: hasGoals
                                  ? (selected) {
                                      setState(() {
                                        if (selected == true) {
                                          _selectedAthletes.add(userId);
                                        } else {
                                          _selectedAthletes.remove(userId);
                                        }
                                      });
                                    }
                                  : null,
                              title: Text(
                                athlete['full_name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        hasGoals ? Icons.check_circle : Icons.warning,
                                        size: 16,
                                        color: hasGoals ? Colors.green : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasGoals ? 'Goals set' : 'Goals missing',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hasGoals ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (assessment != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'AISRI components: R:${assessment['running_performance']} S:${assessment['strength']} ROM:${assessment['rom']} B:${assessment['balance']} M:${assessment['mobility']} A:${assessment['alignment']}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                  ],
                                ],
                              ),
                              secondary: hasGoals
                                  ? const Icon(Icons.person, color: Colors.blue)
                                  : Icon(Icons.person_outline, color: Colors.grey[400]),
                            ),
                          );
                        },
                      ),
          ),

          // Analysis Results
          if (_analysisResults.isNotEmpty) ...[
            const Divider(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Analysis Results',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._analysisResults.map((result) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              result['athlete_name'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'AISRI: ${result['aisri_score'].toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPhaseColor(result['training_phase']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                result['training_phase'],
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'Foundation':
        return Colors.blue;
      case 'Endurance':
        return Colors.cyan;
      case 'Threshold':
        return Colors.orange;
      case 'Peak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
