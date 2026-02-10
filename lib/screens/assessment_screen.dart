import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;

  // Assessment scores (0-100)
  double _mobilityScore = 50;
  double _strengthScore = 50;
  double _enduranceScore = 50;
  double _flexibilityScore = 50;
  double _balanceScore = 50;

  String _assessmentType = 'full';
  final _notesController = TextEditingController();

  int get _totalScore {
    return ((_mobilityScore * 2) +
            (_strengthScore * 2) +
            (_enduranceScore * 3) +
            (_flexibilityScore * 2) +
            _balanceScore)
        .round();
  }

  String get _riskLevel {
    if (_totalScore >= 800) return 'Very Low Risk';
    if (_totalScore >= 600) return 'Low Risk';
    if (_totalScore >= 400) return 'Moderate Risk';
    if (_totalScore >= 200) return 'High Risk';
    return 'Very High Risk';
  }

  Color get _riskColor {
    if (_totalScore >= 800) return Colors.green;
    if (_totalScore >= 600) return Colors.lightGreen;
    if (_totalScore >= 400) return Colors.orange;
    if (_totalScore >= 200) return Colors.deepOrange;
    return Colors.red;
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not authenticated';

      await _supabase.from('AISRI_assessments').insert({
        'athlete_id': userId,
        'total_score': _totalScore,
        'mobility_score': _mobilityScore.round(),
        'strength_score': _strengthScore.round(),
        'endurance_score': _enduranceScore.round(),
        'flexibility_score': _flexibilityScore.round(),
        'balance_score': _balanceScore.round(),
        'assessment_type': _assessmentType,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'assessed_by': userId,
      });

      // Update profile with current AISRI score
      await _supabase.from('profiles').update({
        'current_AISRI_score': _totalScore,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AISRI Assessment'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const ClampingScrollPhysics(),
            children: [
              // Score Display Card
              Card(
                elevation: 4,
                color: _riskColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                    Text(
                      _totalScore.toString(),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _riskColor,
                      ),
                    ),
                    Text(
                      _riskLevel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _riskColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Score (0-1000)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Assessment Type
            DropdownButtonFormField<String>(
              initialValue: _assessmentType,
              decoration: const InputDecoration(
                labelText: 'Assessment Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'full', child: Text('Full Assessment')),
                DropdownMenuItem(value: 'quick', child: Text('Quick Check')),
                DropdownMenuItem(value: 'follow_up', child: Text('Follow-up')),
              ],
              onChanged: (value) => setState(() => _assessmentType = value!),
            ),

            const SizedBox(height: 24),
            const Text(
              'Assessment Components',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Mobility Score
            _buildScoreSlider(
              'Mobility',
              _mobilityScore,
              Icons.directions_walk,
              Colors.blue,
              (value) => setState(() => _mobilityScore = value),
            ),

            // Strength Score
            _buildScoreSlider(
              'Strength',
              _strengthScore,
              Icons.fitness_center,
              Colors.red,
              (value) => setState(() => _strengthScore = value),
            ),

            // Endurance Score
            _buildScoreSlider(
              'Endurance',
              _enduranceScore,
              Icons.favorite,
              Colors.pink,
              (value) => setState(() => _enduranceScore = value),
            ),

            // Flexibility Score
            _buildScoreSlider(
              'Flexibility',
              _flexibilityScore,
              Icons.accessibility_new,
              Colors.purple,
              (value) => setState(() => _flexibilityScore = value),
            ),

            // Balance Score
            _buildScoreSlider(
              'Balance',
              _balanceScore,
              Icons.balance,
              Colors.green,
              (value) => setState(() => _balanceScore = value),
            ),

            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Any observations or recommendations...',
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAssessment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Assessment',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildScoreSlider(
    String label,
    double value,
    IconData icon,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.round().toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: color,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
