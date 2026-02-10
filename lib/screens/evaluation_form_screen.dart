import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'assessment_results_screen.dart';
import '../services/aisri_calculator.dart';
import 'dart:developer' as developer;

class EvaluationFormScreen extends StatefulWidget {
  const EvaluationFormScreen({super.key});

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 7;
  bool _isLoading = false;

  // Step 1: Personal Information
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Step 2: Training Background
  final _yearsRunningController = TextEditingController();
  final _weeklyMileageController = TextEditingController();
  String _selectedTrainingFrequency = '3-4 days/week';
  double _trainingIntensity = 5.0;

  // Step 3: Injury History
  final _injuryHistoryController = TextEditingController();
  double _currentPain = 0.0;
  final _monthsInjuryFreeController = TextEditingController();

  // Step 4: Recovery Metrics
  final _sleepHoursController = TextEditingController();
  double _sleepQuality = 7.0;
  double _stressLevel = 5.0;

  // Step 5: Performance Data
  final _recent5kController = TextEditingController();
  final _recent10kController = TextEditingController();
  final _recentHalfController = TextEditingController();
  String _selectedFitnessLevel = 'Intermediate';

  // Step 6: Physical Assessments (15 tests)
  // Lower Body (6)
  final _ankleDorsiflexionController = TextEditingController();
  final _kneeFlexionController = TextEditingController();
  String _selectedKneeStrength = 'Moderate (45-90°)';
  final _hipFlexionController = TextEditingController();
  final _hipAbductionController = TextEditingController();
  final _hamstringFlexController = TextEditingController();
  // Core & Balance (2)
  final _balanceTestController = TextEditingController();
  final _plankHoldController = TextEditingController();
  // Upper Body (4)
  final _shoulderFlexionController = TextEditingController();
  final _shoulderAbductionController = TextEditingController();
  String _selectedShoulderRotation = 'Mid-back';
  final _neckRotationController = TextEditingController();
  String _selectedNeckFlexion = 'Within 2cm';
  // Cardiovascular & Recovery (2)
  final _restingHRController = TextEditingController();
  double _perceivedFatigue = 5.0;

  // Step 7: Goals
  String _selectedRaceDistance = '10K';
  DateTime _targetRaceDate = DateTime.now().add(const Duration(days: 90));
  String _selectedPrimaryGoal = 'PR time';

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _yearsRunningController.dispose();
    _weeklyMileageController.dispose();
    _injuryHistoryController.dispose();
    _monthsInjuryFreeController.dispose();
    _sleepHoursController.dispose();
    _recent5kController.dispose();
    _recent10kController.dispose();
    _recentHalfController.dispose();
    // Physical Assessments
    _ankleDorsiflexionController.dispose();
    _kneeFlexionController.dispose();
    _hipFlexionController.dispose();
    _hipAbductionController.dispose();
    _hamstringFlexController.dispose();
    _balanceTestController.dispose();
    _plankHoldController.dispose();
    _shoulderFlexionController.dispose();
    _shoulderAbductionController.dispose();
    _neckRotationController.dispose();
    _restingHRController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Personal Info
        if (_ageController.text.isEmpty) {
          _showError('Please enter your age');
          return false;
        }
        final age = int.tryParse(_ageController.text);
        if (age == null || age < 13 || age > 100) {
          _showError('Age must be between 13 and 100');
          return false;
        }
        if (_weightController.text.isEmpty) {
          _showError('Please enter your weight');
          return false;
        }
        final weight = double.tryParse(_weightController.text);
        if (weight == null || weight < 30 || weight > 200) {
          _showError('Weight must be between 30 and 200 kg');
          return false;
        }
        if (_heightController.text.isEmpty) {
          _showError('Please enter your height');
          return false;
        }
        final height = double.tryParse(_heightController.text);
        if (height == null || height < 120 || height > 250) {
          _showError('Height must be between 120 and 250 cm');
          return false;
        }
        return true;

      case 1: // Training Background
        if (_yearsRunningController.text.isEmpty) {
          _showError('Please enter years of running experience');
          return false;
        }
        final years = double.tryParse(_yearsRunningController.text);
        if (years == null || years < 0 || years > 50) {
          _showError('Years must be between 0 and 50');
          return false;
        }
        if (_weeklyMileageController.text.isEmpty) {
          _showError('Please enter your weekly mileage');
          return false;
        }
        final mileage = double.tryParse(_weeklyMileageController.text);
        if (mileage == null || mileage < 0) {
          _showError('Please enter a valid weekly mileage');
          return false;
        }
        return true;

      case 2: // Injury History
        if (_monthsInjuryFreeController.text.isEmpty) {
          _showError('Please enter months injury-free');
          return false;
        }
        final months = int.tryParse(_monthsInjuryFreeController.text);
        if (months == null || months < 0 || months > 120) {
          _showError('Months must be between 0 and 120');
          return false;
        }
        return true;

      case 3: // Recovery Metrics
        if (_sleepHoursController.text.isEmpty) {
          _showError('Please enter average sleep hours');
          return false;
        }
        final sleep = double.tryParse(_sleepHoursController.text);
        if (sleep == null || sleep < 4 || sleep > 12) {
          _showError('Sleep hours must be between 4 and 12');
          return false;
        }
        return true;

      case 4: // Performance Data
        if (_recent5kController.text.isEmpty) {
          _showError('Please enter your recent 5K time (mm:ss)');
          return false;
        }
        return true;

      case 5: // Physical Assessments (15 tests)
        // Lower Body
        if (_ankleDorsiflexionController.text.isEmpty) {
          _showError('Please enter ankle dorsiflexion distance');
          return false;
        }
        final ankle = double.tryParse(_ankleDorsiflexionController.text);
        if (ankle == null || ankle < 0 || ankle > 25) {
          _showError('Ankle dorsiflexion must be between 0 and 25 cm');
          return false;
        }
        if (_kneeFlexionController.text.isEmpty) {
          _showError('Please enter knee flexion gap');
          return false;
        }
        final kneeFlex = double.tryParse(_kneeFlexionController.text);
        if (kneeFlex == null || kneeFlex < 0 || kneeFlex > 30) {
          _showError('Knee flexion gap must be between 0 and 30 cm');
          return false;
        }
        if (_hipFlexionController.text.isEmpty) {
          _showError('Please enter hip flexion angle');
          return false;
        }
        final hipFlex = int.tryParse(_hipFlexionController.text);
        if (hipFlex == null || hipFlex < 90 || hipFlex > 140) {
          _showError('Hip flexion must be between 90 and 140 degrees');
          return false;
        }
        if (_hipAbductionController.text.isEmpty) {
          _showError('Please enter hip abduction reps');
          return false;
        }
        final hipAbd = int.tryParse(_hipAbductionController.text);
        if (hipAbd == null || hipAbd < 0 || hipAbd > 50) {
          _showError('Hip abduction must be between 0 and 50 reps');
          return false;
        }
        if (_hamstringFlexController.text.isEmpty) {
          _showError('Please enter hamstring flexibility');
          return false;
        }
        final hamstring = double.tryParse(_hamstringFlexController.text);
        if (hamstring == null || hamstring < -20 || hamstring > 30) {
          _showError('Hamstring flexibility must be between -20 and 30 cm');
          return false;
        }
        // Core & Balance
        if (_balanceTestController.text.isEmpty) {
          _showError('Please enter balance test result');
          return false;
        }
        final balance = int.tryParse(_balanceTestController.text);
        if (balance == null || balance < 0 || balance > 30) {
          _showError('Balance test must be between 0 and 30 seconds');
          return false;
        }
        if (_plankHoldController.text.isEmpty) {
          _showError('Please enter plank hold time');
          return false;
        }
        final plank = int.tryParse(_plankHoldController.text);
        if (plank == null || plank < 0 || plank > 300) {
          _showError('Plank hold must be between 0 and 300 seconds');
          return false;
        }
        // Upper Body
        if (_shoulderFlexionController.text.isEmpty) {
          _showError('Please enter shoulder flexion angle');
          return false;
        }
        final shoulderFlex = int.tryParse(_shoulderFlexionController.text);
        if (shoulderFlex == null || shoulderFlex < 90 || shoulderFlex > 180) {
          _showError('Shoulder flexion must be between 90 and 180 degrees');
          return false;
        }
        if (_shoulderAbductionController.text.isEmpty) {
          _showError('Please enter shoulder abduction angle');
          return false;
        }
        final shoulderAbd = int.tryParse(_shoulderAbductionController.text);
        if (shoulderAbd == null || shoulderAbd < 90 || shoulderAbd > 180) {
          _showError('Shoulder abduction must be between 90 and 180 degrees');
          return false;
        }
        if (_neckRotationController.text.isEmpty) {
          _showError('Please enter neck rotation angle');
          return false;
        }
        final neckRot = int.tryParse(_neckRotationController.text);
        if (neckRot == null || neckRot < 0 || neckRot > 90) {
          _showError('Neck rotation must be between 0 and 90 degrees');
          return false;
        }
        // Cardiovascular
        if (_restingHRController.text.isEmpty) {
          _showError('Please enter resting heart rate');
          return false;
        }
        final hr = int.tryParse(_restingHRController.text);
        if (hr == null || hr < 40 || hr > 100) {
          _showError('Resting heart rate must be between 40 and 100 BPM');
          return false;
        }
        return true;

      case 6: // Goals
        return true;

      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitForm();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      developer.log('🔍 DEBUG: Starting AISRI calculation...');
      developer.log('Years running: ${_yearsRunningController.text}');
      developer.log('Training frequency: $_selectedTrainingFrequency');
      developer.log('Training intensity: $_trainingIntensity');
      developer.log('Current pain: $_currentPain');
      developer.log('Sleep hours: ${_sleepHoursController.text}');
      developer.log('Sleep quality: $_sleepQuality');
      developer.log('Stress level: $_stressLevel');
      developer.log('Weekly mileage: ${_weeklyMileageController.text}');
      developer.log('Fitness level: $_selectedFitnessLevel');
      developer
          .log('Ankle dorsiflexion: ${_ankleDorsiflexionController.text} cm');
      developer.log('Hip flexion: ${_hipFlexionController.text}°');
      developer.log('Balance test: ${_balanceTestController.text}s');
      developer.log('Plank hold: ${_plankHoldController.text}s');
      developer.log('Resting HR: ${_restingHRController.text} BPM');
      developer.log('Perceived fatigue: $_perceivedFatigue');
      developer.log('Knee strength: $_selectedKneeStrength');
      developer.log('Shoulder rotation: $_selectedShoulderRotation');
      developer.log('Neck flexion: $_selectedNeckFlexion');

      // Calculate AISRI score using the calculator service
      final scoreData = AISRICalculator.calculateScore({
        'years_running': double.parse(_yearsRunningController.text).toInt(),
        'training_frequency': _selectedTrainingFrequency,
        'training_intensity': _trainingIntensity.toInt(),
        'injury_history': _injuryHistoryController.text,
        'current_pain': _currentPain.toInt(),
        'months_injury_free': int.parse(_monthsInjuryFreeController.text),
        'sleep_hours': double.parse(_sleepHoursController.text),
        'sleep_quality': _sleepQuality.toInt(),
        'stress_level': _stressLevel.toInt(),
        'weekly_mileage': double.parse(_weeklyMileageController.text),
        'fitness_level': _selectedFitnessLevel,

        // Physical Assessment Data for enhanced AISRI calculation
        'ankle_dorsiflexion_cm':
            double.parse(_ankleDorsiflexionController.text),
        'knee_flexion_gap_cm': double.parse(_kneeFlexionController.text),
        'knee_extension_strength': _selectedKneeStrength,
        'hip_flexion_angle': int.parse(_hipFlexionController.text),
        'hip_abduction_reps': int.parse(_hipAbductionController.text),
        'hamstring_flexibility_cm': double.parse(_hamstringFlexController.text),
        'balance_test_seconds': int.parse(_balanceTestController.text),
        'plank_hold_seconds': int.parse(_plankHoldController.text),
        'shoulder_flexion_angle': int.parse(_shoulderFlexionController.text),
        'shoulder_abduction_angle':
            int.parse(_shoulderAbductionController.text),
        'shoulder_internal_rotation': _selectedShoulderRotation,
        'neck_rotation_angle': int.parse(_neckRotationController.text),
        'neck_flexion_status': _selectedNeckFlexion,
        'resting_heart_rate': int.parse(_restingHRController.text),
        'perceived_fatigue': _perceivedFatigue.toInt(),
      });

      // Debug: Check calculator output
      developer.log('🎯 DEBUG: AISRI Calculator returned:');
      developer.log('Full scoreData: $scoreData');
      developer.log('AISRI Score: ${scoreData['AISRI_score']}');
      developer.log('Risk Level: ${scoreData['risk_level']}');
      developer.log('Pillar Adaptability: ${scoreData['pillar_adaptability']}');
      developer.log('Pillar Injury Risk: ${scoreData['pillar_injury_risk']}');
      developer.log('Pillar Fatigue: ${scoreData['pillar_fatigue']}');
      developer.log('Pillar Recovery: ${scoreData['pillar_recovery']}');
      developer.log('Pillar Intensity: ${scoreData['pillar_intensity']}');
      developer.log('Pillar Consistency: ${scoreData['pillar_consistency']}');

      if (scoreData['AISRI_score'] == null) {
        throw Exception('AISRI calculation failed - score is null');
      }

      // Insert assessment with calculated scores
      await Supabase.instance.client
          .from('AISRI_assessments')
          .insert({
            // User identification
            'user_id': userId,

            // Personal Info (Step 1)
            'age': int.parse(_ageController.text),
            'gender': _selectedGender,
            'weight': double.parse(_weightController.text),
            'height': double.parse(_heightController.text),

            // Training Background (Step 2)
            'years_running': double.parse(_yearsRunningController.text),
            'weekly_mileage': double.parse(_weeklyMileageController.text),
            'training_frequency': _selectedTrainingFrequency,
            'training_intensity': _trainingIntensity.toInt(),

            // Injury History (Step 3)
            'injury_history': _injuryHistoryController.text,
            'current_pain': _currentPain.toInt(),
            'months_injury_free': int.parse(_monthsInjuryFreeController.text),

            // Recovery Metrics (Step 4)
            'sleep_hours': double.parse(_sleepHoursController.text),
            'sleep_quality': _sleepQuality.toInt(),
            'stress_level': _stressLevel.toInt(),

            // Performance Data (Step 5)
            'recent_5k_time': _recent5kController.text,
            'recent_10k_time': _recent10kController.text.isNotEmpty
                ? _recent10kController.text
                : null,
            'recent_half_time': _recentHalfController.text.isNotEmpty
                ? _recentHalfController.text
                : null,
            'fitness_level': _selectedFitnessLevel,

            // Physical Assessments (Step 6) - 15 tests
            'ankle_dorsiflexion_cm':
                double.parse(_ankleDorsiflexionController.text),
            'knee_flexion_gap_cm': double.parse(_kneeFlexionController.text),
            'knee_extension_strength': _selectedKneeStrength,
            'hip_flexion_angle': int.parse(_hipFlexionController.text),
            'hip_abduction_reps': int.parse(_hipAbductionController.text),
            'hamstring_flexibility_cm':
                double.parse(_hamstringFlexController.text),
            'balance_test_seconds': int.parse(_balanceTestController.text),
            'plank_hold_seconds': int.parse(_plankHoldController.text),
            'shoulder_flexion_angle':
                int.parse(_shoulderFlexionController.text),
            'shoulder_abduction_angle':
                int.parse(_shoulderAbductionController.text),
            'shoulder_internal_rotation': _selectedShoulderRotation,
            'neck_rotation_angle': int.parse(_neckRotationController.text),
            'neck_flexion_status': _selectedNeckFlexion,
            'resting_heart_rate': int.parse(_restingHRController.text),
            'perceived_fatigue': _perceivedFatigue.toInt(),

            // Goals (Step 7)
            'target_race_distance': _selectedRaceDistance,
            'target_race_date': _targetRaceDate.toIso8601String(),
            'primary_goal': _selectedPrimaryGoal,

            // AISRI Calculated Fields
            'total_score': scoreData['AISRI_score'],
            'AISRI_score': scoreData['AISRI_score'],
            'risk_level': scoreData['risk_level'],
            'score_calculated_at': DateTime.now().toIso8601String(),
            'pillar_adaptability': scoreData['pillar_adaptability'],
            'pillar_injury_risk': scoreData['pillar_injury_risk'],
            'pillar_fatigue': scoreData['pillar_fatigue'],
            'pillar_recovery': scoreData['pillar_recovery'],
            'pillar_intensity': scoreData['pillar_intensity'],
            'pillar_consistency': scoreData['pillar_consistency'],

            // Metadata
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      developer.log('✅ Assessment saved successfully!');

      // Update profile with current AISRI score
      await Supabase.instance.client.from('profiles').update(
          {'current_AISRI_score': scoreData['AISRI_score']}).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment completed successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Assessment Results Screen with all data
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AssessmentResultsScreen(
              assessmentData: {
                'user_id': userId,
                'age': int.tryParse(_ageController.text),
                'gender': _selectedGender,
                'weight': double.tryParse(_weightController.text),
                'height': double.tryParse(_heightController.text),
                'ankle_dorsiflexion_cm':
                    double.tryParse(_ankleDorsiflexionController.text),
                'knee_flexion_gap_cm':
                    double.tryParse(_kneeFlexionController.text),
                'knee_extension_strength': _selectedKneeStrength,
                'hip_flexion_angle': int.tryParse(_hipFlexionController.text),
                'hip_abduction_reps':
                    int.tryParse(_hipAbductionController.text),
                'hamstring_flexibility_cm':
                    double.tryParse(_hamstringFlexController.text),
                'balance_test_seconds':
                    int.tryParse(_balanceTestController.text),
                'plank_hold_seconds': int.tryParse(_plankHoldController.text),
                'shoulder_flexion_angle':
                    int.tryParse(_shoulderFlexionController.text),
                'shoulder_abduction_angle':
                    int.tryParse(_shoulderAbductionController.text),
                'shoulder_internal_rotation': _selectedShoulderRotation,
                'neck_rotation_angle':
                    int.tryParse(_neckRotationController.text),
                'neck_flexion_status': _selectedNeckFlexion,
                'resting_heart_rate': int.tryParse(_restingHRController.text),
                'perceived_fatigue': _perceivedFatigue.toInt(),
                'previous_injuries': _injuryHistoryController.text,
                'current_pain': _currentPain.toInt(),
                'weekly_mileage':
                    double.tryParse(_weeklyMileageController.text),
                'goals': _selectedPrimaryGoal,
                'years_running': double.tryParse(_yearsRunningController.text),
                'training_frequency': _selectedTrainingFrequency,
                'target_race_distance': _selectedRaceDistance,
                'target_race_date': _targetRaceDate.toIso8601String(),
              },
              aistriScore: scoreData['AISRI_score'],
              pillarScores: {
                'Adaptability': scoreData['pillar_adaptability'],
                'Injury Risk': scoreData['pillar_injury_risk'],
                'Fatigue Management': scoreData['pillar_fatigue'],
                'Recovery Capacity': scoreData['pillar_recovery'],
                'Training Intensity': scoreData['pillar_intensity'],
                'Consistency': scoreData['pillar_consistency'],
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('❌ ERROR saving assessment: $e');
      developer.log('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving assessment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Convert training frequency string to number of days

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Athlete Assessment'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildStep1PersonalInfo(),
                _buildStep2TrainingBackground(),
                _buildStep3InjuryHistory(),
                _buildStep4RecoveryMetrics(),
                _buildStep5PerformanceData(),
                _buildStep6PhysicalAssessments(),
                _buildStep7Goals(),
              ],
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                              color: Colors.deepPurple, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                          : Text(
                              _currentStep == _totalSteps - 1
                                  ? 'Complete Assessment'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildStep1PersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about yourself',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Age *',
              suffixText: 'years',
              hintText: 'Enter your age',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.cake),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your age';
              }
              final age = int.tryParse(value);
              if (age == null || age < 16 || age > 100) {
                return 'Please enter valid age (16-100)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.wc),
            ),
            items: ['Male', 'Female', 'Other']
                .map((gender) =>
                    DropdownMenuItem(value: gender, child: Text(gender)))
                .toList(),
            onChanged: (value) => setState(() => _selectedGender = value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Weight *',
              suffixText: 'kg',
              hintText: 'Enter your weight',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.monitor_weight),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight < 30 || weight > 200) {
                return 'Please enter valid weight (30-200 kg)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Height *',
              suffixText: 'cm',
              hintText: 'Enter your height',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.height),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter height';
              }
              final height = double.tryParse(value);
              if (height == null || height < 100 || height > 250) {
                return 'Please enter valid height (100-250 cm)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2TrainingBackground() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_run, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Training Background',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your running experience',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _yearsRunningController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Years of Running Experience',
              hintText: 'How many years have you been running?',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weeklyMileageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Weekly Mileage (km)',
              hintText: 'Average kilometers per week',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.route),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedTrainingFrequency,
            decoration: InputDecoration(
              labelText: 'Training Frequency',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.event_repeat),
            ),
            items: [
              '1-2 days/week',
              '3-4 days/week',
              '5-6 days/week',
              '7+ days/week'
            ]
                .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedTrainingFrequency = value!),
          ),
          const SizedBox(height: 24),
          Text(
            'Training Intensity: ${_trainingIntensity.toInt()}/10',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _trainingIntensity,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.deepPurple,
            label: _trainingIntensity.toInt().toString(),
            onChanged: (value) => setState(() => _trainingIntensity = value),
          ),
          Text(
            'Light                    Moderate                    Intense',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3InjuryHistory() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.healing, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Injury History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us understand your injury background',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _injuryHistoryController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Past Injuries',
              hintText: 'List any running-related injuries (or write "None")',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Current Pain Level: ${_currentPain.toInt()}/10',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _currentPain,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: _currentPain > 5 ? Colors.red : Colors.green,
            label: _currentPain.toInt().toString(),
            onChanged: (value) => setState(() => _currentPain = value),
          ),
          Text(
            'No pain                                        Severe pain',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _monthsInjuryFreeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Months Injury-Free',
              hintText: 'How many months without injury?',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.check_circle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4RecoveryMetrics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bedtime, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Recovery Metrics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Sleep and stress affect performance',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _sleepHoursController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Average Sleep Hours',
              hintText: 'Hours per night (e.g., 7.5)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.nightlight_rounded),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sleep Quality: ${_sleepQuality.toInt()}/10',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _sleepQuality,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.deepPurple,
            label: _sleepQuality.toInt().toString(),
            onChanged: (value) => setState(() => _sleepQuality = value),
          ),
          Text(
            'Poor                                              Excellent',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Text(
            'Stress Level: ${_stressLevel.toInt()}/10',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _stressLevel,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: _stressLevel > 7 ? Colors.red : Colors.green,
            label: _stressLevel.toInt().toString(),
            onChanged: (value) => setState(() => _stressLevel = value),
          ),
          Text(
            'Very calm                                      Very stressed',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5PerformanceData() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Performance Data',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent race times',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _recent5kController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Recent 5K Time',
              hintText: 'mm:ss (e.g., 25:30)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.timer),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _recent10kController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Recent 10K Time (optional)',
              hintText: 'mm:ss (e.g., 52:00)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.timer),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _recentHalfController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Recent Half Marathon Time (optional)',
              hintText: 'hh:mm:ss (e.g., 1:55:00)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.timer),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedFitnessLevel,
            decoration: InputDecoration(
              labelText: 'Current Fitness Level',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.fitness_center),
            ),
            items: ['Beginner', 'Intermediate', 'Advanced', 'Elite']
                .map((level) =>
                    DropdownMenuItem(value: level, child: Text(level)))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedFitnessLevel = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildStep6PhysicalAssessments() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.accessibility_new,
              size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Physical Assessments',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete all 15 physical tests (takes ~20 minutes)',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Coach/Physio Assistance Required Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These physical tests require coach or physiotherapist assistance for accurate measurement and observation.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ========== LOWER BODY (6 TESTS) ==========
          _buildSectionHeader('Lower Body Assessment', Icons.directions_run),
          const SizedBox(height: 16),

          // 1. Ankle Dorsiflexion
          _buildTestContainer(
            imagePath:
                'assets/images/assessments/Proper Ankle Dorsiflexion Test.png',
            title: 'Ankle Dorsiflexion',
            instructions:
                '1. Face wall, foot perpendicular\n2. Lunge forward, knee touches wall\n3. Heel must stay flat on ground\n4. Measure toe-to-wall distance',
            controller: _ankleDorsiflexionController,
            labelText: 'Ankle Dorsiflexion (cm)',
            hintText: 'Enter distance (0-25 cm)',
            helperText: 'Normal: 9-12cm or more',
          ),

          // 2. Knee Flexion ROM
          _buildTestContainer(
            imagePath:
                'assets/images/assessments/Knee Flexion (Heel-to-Buttock) Test.png',
            title: 'Knee Flexion ROM',
            instructions:
                '1. Lie face down\n2. Bend knee, try to touch heel to buttock\n3. Measure gap distance in cm',
            controller: _kneeFlexionController,
            labelText: 'Heel to Buttock Gap (cm)',
            hintText: 'Enter gap (0-30 cm)',
            helperText: 'Normal: <5cm',
          ),

          // 3. Knee Extension Strength
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/assessments/Single-Leg Squat Depth.png',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Single-Leg Squat Depth',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Stand on one leg\n2. Squat down as far as possible\n3. Maintain balance and control',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedKneeStrength,
                  decoration: const InputDecoration(
                    labelText: 'Squat Depth',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    'Deep squat (>90°)',
                    'Moderate (45-90°)',
                    'Cannot perform (<45°)'
                  ]
                      .map((depth) =>
                          DropdownMenuItem(value: depth, child: Text(depth)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedKneeStrength = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Hip Flexion ROM
          _buildTestContainer(
            imagePath: 'assets/images/assessments/Hip Flexion ROM Test.png',
            title: 'Hip Flexion ROM',
            instructions:
                '1. Lie on back\n2. Pull knee to chest\n3. Estimate angle in degrees',
            controller: _hipFlexionController,
            labelText: 'Hip Flexion Angle (degrees)',
            hintText: 'Enter angle (90-140°)',
            helperText: 'Normal: 120° or more',
          ),

          // 5. Hip Abduction Strength
          _buildTestContainer(
            imagePath:
                'assets/images/assessments/Hip Abduction Strength Test.png',
            title: 'Hip Abduction Strength',
            instructions:
                '1. Lie on side\n2. Lift top leg repeatedly\n3. Count reps until fatigue',
            controller: _hipAbductionController,
            labelText: 'Hip Abduction Reps',
            hintText: 'Enter reps (0-50)',
            helperText: 'Normal: 25+ reps',
          ),

          // 6. Hamstring Flexibility
          _buildTestContainer(
            imagePath:
                'assets/images/assessments/Hamstring Flexibility (Sit-and-Reach).png',
            title: 'Hamstring Flexibility',
            instructions:
                '1. Sit with legs straight\n2. Reach toward toes\n3. Measure distance (- if past toes, + if short)',
            controller: _hamstringFlexController,
            labelText: 'Sit-and-Reach Distance (cm)',
            hintText: 'Enter distance (-20 to +30 cm)',
            helperText: 'Normal: 0 to +5cm',
          ),

          // ========== CORE & BALANCE (2 TESTS) ==========
          const SizedBox(height: 32),
          _buildSectionHeader('Core & Balance', Icons.fitness_center),
          const SizedBox(height: 16),

          // 7. Single-Leg Balance
          _buildTestContainer(
            imagePath:
                'assets/images/assessments/balance test instructional diagram.png',
            title: 'Single-Leg Balance',
            instructions:
                '1. Stand on one leg\n2. Close eyes\n3. Record time until balance lost',
            controller: _balanceTestController,
            labelText: 'Balance Time (seconds)',
            hintText: 'Enter seconds (0-30)',
            helperText: 'Normal: 20+ seconds',
          ),

          // 8. Core Strength (Plank)
          _buildTestContainer(
            imagePath: 'assets/images/assessments/Plank Hold Test.png',
            title: 'Core Strength (Plank)',
            instructions:
                '1. Hold front plank with proper form\n2. Keep body straight\n3. Record time until form breaks',
            controller: _plankHoldController,
            labelText: 'Plank Hold Time (seconds)',
            hintText: 'Enter seconds (0-300)',
            helperText: 'Normal: 60+ seconds',
          ),

          // ========== UPPER BODY (4 TESTS) ==========
          const SizedBox(height: 32),
          _buildSectionHeader('Upper Body Mobility', Icons.accessibility),
          const SizedBox(height: 16),

          // 9. Shoulder Flexion ROM
          _buildTestContainer(
            imagePath: 'assets/images/assessments/Shoulder Flexion ROM.png',
            title: 'Shoulder Flexion ROM',
            instructions:
                '1. Raise arm forward and overhead\n2. Keep arm straight\n3. Estimate maximum angle',
            controller: _shoulderFlexionController,
            labelText: 'Shoulder Flexion Angle (degrees)',
            hintText: 'Enter angle (90-180°)',
            helperText: 'Normal: 170-180°',
          ),

          // 10. Shoulder Abduction ROM
          _buildTestContainer(
            imagePath:
                'assets/images/assessments/Shoulder Abduction ROM Test.png',
            title: 'Shoulder Abduction ROM',
            instructions:
                '1. Raise arm sideways to overhead\n2. Keep arm straight\n3. Estimate angle',
            controller: _shoulderAbductionController,
            labelText: 'Shoulder Abduction Angle (degrees)',
            hintText: 'Enter angle (90-180°)',
            helperText: 'Normal: 170-180°',
          ),

          // 11. Shoulder Internal Rotation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/assessments/Shoulder Internal Rotation (Scratch Test).png',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shoulder Internal Rotation (Scratch Test)',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Reach behind back\n2. Try to reach as high as possible\n3. Note highest point reached',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedShoulderRotation,
                  decoration: const InputDecoration(
                    labelText: 'Highest Point Reached',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: ['Cannot reach', 'Lower back', 'Mid-back']
                      .map((level) =>
                          DropdownMenuItem(value: level, child: Text(level)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedShoulderRotation = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 12. Neck Rotation ROM
          _buildTestContainer(
            imagePath: 'assets/images/assessments/Neck Rotation ROM.png',
            title: 'Neck Rotation ROM',
            instructions:
                '1. Turn head to look over shoulder\n2. Estimate angle\n3. Average both sides',
            controller: _neckRotationController,
            labelText: 'Neck Rotation (degrees)',
            hintText: 'Enter angle (0-90°)',
            helperText: 'Normal: 70-90°',
          ),

          // 13. Neck Flexion
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/assessments/Neck Flexion (Chin-to-Chest).png',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Neck Flexion (Chin-to-Chest Test)',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Stand or sit upright\n2. Bring chin down toward chest\n3. Note gap distance',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedNeckFlexion,
                  decoration: const InputDecoration(
                    labelText: 'Chin-to-Chest Result',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: ['Within 2cm', '2-5cm gap', '>5cm gap']
                      .map((result) =>
                          DropdownMenuItem(value: result, child: Text(result)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedNeckFlexion = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ========== CARDIOVASCULAR & RECOVERY (2 TESTS) ==========
          const SizedBox(height: 32),
          _buildSectionHeader('Cardiovascular & Recovery', Icons.favorite),
          const SizedBox(height: 16),

          // 14. Resting Heart Rate
          _buildTestContainer(
            imagePath: 'assets/images/assessments/Heart Rate Check.png',
            title: 'Resting Heart Rate',
            instructions:
                '1. Check pulse immediately after waking\n2. Count for 60 seconds\n3. Record BPM',
            controller: _restingHRController,
            labelText: 'Resting Heart Rate (BPM)',
            hintText: 'Enter BPM (40-100)',
            helperText: 'Normal: 60-80 BPM',
          ),

          // 15. Perceived Fatigue (Slider)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/assessments/Fatigue Scale Visual.png',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Perceived Fatigue Level',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rate your current overall fatigue level',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Current Level: ${_perceivedFatigue.toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Slider(
                  value: _perceivedFatigue,
                  min: 1.0,
                  max: 10.0,
                  divisions: 90,
                  label: _perceivedFatigue.toStringAsFixed(1),
                  activeColor: Colors.purple[700],
                  onChanged: (value) =>
                      setState(() => _perceivedFatigue = value),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 = Energized',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text('10 = Exhausted',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These 15 physical assessments provide a comprehensive analysis of your injury risk and physical capabilities.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 28, color: Colors.purple[700]),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple[800],
          ),
        ),
      ],
    );
  }

  // Helper method to build test containers with text input
  Widget _buildTestContainer({
    required String imagePath,
    required String title,
    required String instructions,
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required String helperText,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                instructions,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                  helperText: helperText,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep7Goals() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag, size: 64, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Your Goals',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'What are you training for?',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            initialValue: _selectedRaceDistance,
            decoration: InputDecoration(
              labelText: 'Target Race Distance',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.straighten),
            ),
            items: ['5K', '10K', 'Half Marathon', 'Marathon', 'Ultra']
                .map((distance) =>
                    DropdownMenuItem(value: distance, child: Text(distance)))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedRaceDistance = value!),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
            title: const Text('Target Race Date'),
            subtitle: Text(
              '${_targetRaceDate.day}/${_targetRaceDate.month}/${_targetRaceDate.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _targetRaceDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) {
                setState(() => _targetRaceDate = picked);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedPrimaryGoal,
            decoration: InputDecoration(
              labelText: 'Primary Goal',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.star),
            ),
            items: ['Complete race', 'PR time', 'Stay healthy', 'Build fitness']
                .map((goal) => DropdownMenuItem(value: goal, child: Text(goal)))
                .toList(),
            onChanged: (value) => setState(() => _selectedPrimaryGoal = value!),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'After completing this assessment, we\'ll calculate your AISRI score and create a personalized training plan.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
